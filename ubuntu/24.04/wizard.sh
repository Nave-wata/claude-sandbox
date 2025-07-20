#!/usr/bin/env bash
# Claude Sandbox Wizard
# This script manages installation, configuration, and uninstallation of claude-sandbox

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="claude-sandbox"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check privileges and set installation directory
check_privileges() {
    # Get the original user when running with sudo
    ORIGINAL_USER="${SUDO_USER:-$USER}"
    ORIGINAL_HOME=$(eval echo "~$ORIGINAL_USER")
    
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running with root privileges. Installing system-wide to /usr/local/bin"
        INSTALL_DIR="/usr/local/bin"
        USER_HOME="$ORIGINAL_HOME"
    else
        log_info "Running as regular user. Installing to user directory"
        INSTALL_DIR="$HOME/.local/bin"
        USER_HOME="$HOME"
        mkdir -p "$INSTALL_DIR"
    fi
    
    log_info "Target user: $ORIGINAL_USER"
    log_info "User home: $USER_HOME"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        log_info "Visit: https://docs.docker.com/get-docker/"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_warn "Docker daemon is not running or not accessible"
        log_info "Make sure Docker is running and your user has Docker permissions"
    fi
    
    log_info "Prerequisites check passed"
}

# Install claude-sandbox command
install_command() {
    log_step "Installing claude-sandbox command..."
    
    local source_script="$SCRIPT_DIR/$SCRIPT_NAME"
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [[ ! -f "$source_script" ]]; then
        log_error "Source script not found: $source_script"
        exit 1
    fi
    
    # Copy script to install directory
    cp "$source_script" "$target_script"
    chmod +x "$target_script"
    
    log_info "Installed $SCRIPT_NAME to $target_script"
}

# Update PATH if necessary
update_path() {
    if [[ "$INSTALL_DIR" == "$USER_HOME/.local/bin" ]]; then
        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$USER_HOME/.local/bin:"* ]]; then
            log_step "Adding $USER_HOME/.local/bin to PATH..."
            
            # Add to .bashrc
            if [[ -f "$USER_HOME/.bashrc" ]]; then
                echo "" >> "$USER_HOME/.bashrc"
                echo "# Added by claude-sandbox installer" >> "$USER_HOME/.bashrc"
                echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USER_HOME/.bashrc"
                log_info "Added PATH export to $USER_HOME/.bashrc"
            fi
            
            # Apply PATH changes to current shell session immediately
            export PATH="$USER_HOME/.local/bin:$PATH"
            log_info "PATH updated for current session - claude-sandbox is now available"
        fi
    fi
}


# Build Docker image
build_docker_image() {
    log_step "Building Docker image..."
    
    local sandbox_dir="$SCRIPT_DIR/sandbox"
    local image_name="claude-sandbox"
    
    if [[ ! -d "$sandbox_dir" ]]; then
        log_error "Sandbox directory not found: $sandbox_dir"
        exit 1
    fi
    
    if ! docker image inspect "$image_name" &> /dev/null; then
        log_info "Building Claude Sandbox Docker image (this may take a few minutes)..."
        if docker build -t "$image_name" "$sandbox_dir"; then
            log_info "Docker image built successfully"
        else
            log_error "Failed to build Docker image"
            exit 1
        fi
    else
        log_info "Docker image already exists, skipping build"
    fi
}

# Show installation summary
show_summary() {
    log_step "Installation Summary"
    echo ""
    echo "✅ Claude Sandbox has been installed successfully!"
    echo ""
    echo "📍 Installation Details:"
    echo "   Command: $INSTALL_DIR/$SCRIPT_NAME"
    echo "   Docker Image: claude-sandbox (pre-built and ready)"
    echo ""
    echo "🚀 Usage:"
    echo "   claude-sandbox --help               # Show help"
    echo "   claude-sandbox \"analyze this code\" # Run Claude in sandbox"
    echo ""
    echo "🔧 Optional Aliases (add to your shell config):"
    echo "   alias claude='claude-sandbox'       # Use as default claude"
    echo "   alias cs='claude-sandbox'           # Short alias"
    echo ""
    
    if [[ "$INSTALL_DIR" == "$USER_HOME/.local/bin" ]]; then
        echo "✅ claude-sandbox command is ready to use immediately!"
    fi
    
    echo ""
}

# Uninstall function
uninstall() {
    log_step "Uninstalling Claude Sandbox..."
    
    # Stop and remove Docker containers
    log_step "Stopping and removing Docker containers..."
    local containers=$(docker ps -a --filter "ancestor=claude-sandbox" --format "{{.ID}}" 2>/dev/null || true)
    if [[ -n "$containers" ]]; then
        docker stop $containers 2>/dev/null || true
        docker rm $containers 2>/dev/null || true
        log_info "Stopped and removed Claude Sandbox containers"
    else
        log_info "No Claude Sandbox containers found"
    fi
    
    # Remove Docker image
    log_step "Removing Docker image..."
    if docker image inspect "claude-sandbox" &> /dev/null; then
        docker rmi "claude-sandbox" 2>/dev/null || true
        log_info "Removed claude-sandbox Docker image"
    else
        log_info "Claude Sandbox Docker image not found"
    fi
    
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [[ -f "$target_script" ]]; then
        rm -f "$target_script"
        log_info "Removed $target_script"
    fi
    
    
    log_info "Claude Sandbox uninstalled successfully"
}

# Show usage
show_usage() {
    cat << EOF
Claude Sandbox Setup Wizard

USAGE:
    ./wizard.sh [OPTIONS]

OPTIONS:
    --help, -h          Show this help message
    --uninstall, -u     Uninstall claude-sandbox

DESCRIPTION:
    This wizard manages installation, configuration, and uninstallation of
    the claude-sandbox command which provides a containerized Claude Code
    environment with the current directory mounted as the working space.

INSTALLATION:
    - System-wide (requires sudo): /usr/local/bin/claude-sandbox
    - User install: ~/.local/bin/claude-sandbox

EOF
}

# Main function
main() {
    case "${1:-}" in
        --help|-h)
            show_usage
            exit 0
            ;;
        --uninstall|-u)
            check_privileges
            uninstall
            exit 0
            ;;
    esac
    
    echo "🐳 Claude Sandbox Setup Wizard"
    echo "=========================="
    echo ""
    
    check_privileges
    check_prerequisites
    install_command
    update_path
    build_docker_image
    show_summary
}

# Run main function
main "$@"