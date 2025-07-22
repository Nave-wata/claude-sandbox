#!/usr/bin/env bash
# Common functions for claude-sandbox wizard

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="claude-sandbox"
DOCKER_IMAGE="claude-sandbox"

# Logging functions
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

# Interactive confirmation for reinstallation
confirm_reinstall() {
    local target_script="$1"
    
    echo
    log_warn "$SCRIPT_NAME is already installed at $target_script"
    
    # Try to get current installation info
    if [[ -x "$target_script" ]]; then
        echo -e "${BLUE}Current installation details:${NC}"
        echo "  Location: $target_script"
        local install_date
        install_date=$(stat -c %y "$target_script" 2>/dev/null | cut -d' ' -f1 2>/dev/null) || install_date="Unknown"
        echo "  Installed: $install_date"
        
        # Check for Docker image
        if command -v docker >/dev/null 2>&1; then
            local docker_output
            docker_output=$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedAt}}\t{{.Size}}" --no-trunc 2>/dev/null)
            local image_info
            image_info=$(echo "$docker_output" | grep -E "^claude-sandbox\s+latest\s+" || echo "")
            
            if [[ -n "$image_info" ]]; then
                echo "  Docker image: claude-sandbox:latest"
                echo "    $image_info"
            else
                echo "  Docker image: Not found (will be created)"
            fi
        fi
    fi
    
    echo
    echo -e "${YELLOW}Do you want to overwrite the existing installation?${NC}"
    echo "  [y] Yes, reinstall (this will remove and recreate command + Docker image)"
    echo "  [n] No, cancel installation"
    echo
    
    while true; do
        read -p "Choice [y/n]: " choice
        case "$choice" in
            [Yy]|[Yy][Ee][Ss])
                echo
                log_info "Proceeding with reinstallation..."
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo
                return 1
                ;;
            *)
                echo "Please answer y (yes) or n (no)."
                ;;
        esac
    done
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
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local source_script="$script_dir/$SCRIPT_NAME"
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [[ ! -f "$source_script" ]]; then
        log_error "Source script not found: $source_script"
        exit 1
    fi
    
    # Check if already installed and handle interactive confirmation
    if [[ -f "$target_script" ]]; then
        if ! confirm_reinstall "$target_script"; then
            log_info "Installation cancelled by user"
            exit 0
        fi
        
        log_step "Removing existing installation..."
        rm -f "$target_script"
        log_info "Existing installation removed"
    fi
    
    # Copy script to install directory
    cp "$source_script" "$target_script"
    chmod +x "$target_script"
    
    log_info "Installed $SCRIPT_NAME to $target_script"
}

# Generate plugin setup script from template
generate_plugin_setup_script() {
    local plugins="$1"
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local sandbox_dir="$script_dir/sandbox"
    local template_script="$sandbox_dir/setup-plugins.template.sh"
    local setup_script="$sandbox_dir/setup-plugins.sh"
    
    log_step "Generating plugin setup script..."
    
    if [[ ! -f "$template_script" ]]; then
        log_error "Template script not found: $template_script"
        exit 1
    fi
    
    # Copy template to target script
    cp "$template_script" "$setup_script"
    
    # Add plugin installation commands to the end
    if [[ -n "$plugins" ]]; then
        log_info "Adding plugins: $plugins"
        
        echo "" >> "$setup_script"
        echo "# Plugin installations" >> "$setup_script"
        
        # Split plugins by comma and process each
        IFS=',' read -ra PLUGIN_ARRAY <<< "$plugins"
        for plugin in "${PLUGIN_ARRAY[@]}"; do
            # Trim whitespace
            plugin=$(echo "$plugin" | xargs)
            if [[ -n "$plugin" ]]; then
                echo "" >> "$setup_script"
                echo "# Installing and configuring $plugin plugin" >> "$setup_script"
                echo "if ! asdf plugin add $plugin; then" >> "$setup_script"
                echo "    echo \"Warning: Failed to add plugin $plugin\" >&2" >> "$setup_script"
                echo "    echo \"Skipping further operations for plugin $plugin due to error.\" >&2" >> "$setup_script"
                echo "fi" >> "$setup_script"
                echo "if ! asdf install $plugin stable 2>/dev/null && ! asdf install $plugin latest; then" >> "$setup_script"
                echo "    echo \"Warning: Failed to install plugin $plugin\" >&2" >> "$setup_script"
                echo "    echo \"Skipping further operations for plugin $plugin due to error.\" >&2" >> "$setup_script"
                echo "fi" >> "$setup_script"
                echo "if asdf list $plugin | grep -q stable; then" >> "$setup_script"
                echo "    asdf global $plugin stable" >> "$setup_script"
                echo "else" >> "$setup_script"
                echo "    asdf global $plugin latest" >> "$setup_script"
                echo "fi" >> "$setup_script"
            fi
        done
    else
        # Default: only nodejs (already available in base image)
        echo "" >> "$setup_script"
        echo "# No additional plugins specified. Using default nodejs from base image." >> "$setup_script"
    fi
    
    chmod +x "$setup_script"
    log_info "Plugin setup script generated successfully"
}

# Build Docker image
build_docker_image() {
    log_step "Building Docker image..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
    local sandbox_dir="$script_dir/sandbox"
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
        log_info "Rebuilding existing Docker image..."
        if docker build -t "$image_name" "$sandbox_dir"; then
            log_info "Docker image rebuilt successfully"
        else
            log_error "Failed to rebuild Docker image"
            exit 1
        fi
    fi
}

# Show installation summary
show_install_summary() {
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
        echo "⚠️  PATH Setup Required:"
        echo "   Step 1: Try reloading your shell configuration"
        echo "   source ~/.profile"
        echo ""
        echo "   Step 2: Test if the command works"
        echo "   claude-sandbox --help"
        echo ""
        echo "   Step 3: If the command is still not found, add to ~/.bashrc and reload:"
        echo "   echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
        echo "   source ~/.bashrc"
        echo ""
        echo "   Alternative: Restart your terminal instead of using 'source'"
    fi
    
    echo ""
}

# Clean up Docker resources
cleanup_docker() {
    # Stop and remove Docker containers
    log_step "Stopping and removing Docker containers..."
    local containers="$(docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.ID}}" 2>/dev/null || true)"
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs -r docker stop 2>/dev/null || true
        echo "$containers" | xargs -r docker rm 2>/dev/null || true
        log_info "Stopped and removed Claude Sandbox containers"
    else
        log_info "No Claude Sandbox containers found"
    fi
    
    # Remove Docker image
    log_step "Removing Docker image..."
    if docker image inspect "${DOCKER_IMAGE}" &> /dev/null; then
        docker rmi "${DOCKER_IMAGE}" 2>/dev/null || true
        log_info "Removed ${DOCKER_IMAGE} Docker image"
    else
        log_info "Claude Sandbox Docker image not found"
    fi
}

# Interactive confirmation for uninstallation
confirm_uninstall() {
    echo
    log_warn "You are about to uninstall $SCRIPT_NAME"
    
    # Show current installation info
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    if [[ -x "$target_script" ]]; then
        echo -e "${BLUE}Current installation details:${NC}"
        echo "  Location: $target_script"
        local install_date
        local stat_output
        stat_output=$(stat -c %y "$target_script" 2>/dev/null) || stat_output=""
        if [[ -n "$stat_output" ]]; then
            install_date=$(echo "$stat_output" | cut -d' ' -f1 2>/dev/null) || install_date="Unknown"
        else
            install_date="Unknown"
        fi
        echo "  Installed: $install_date"
    fi
    
    # Check for Docker resources
    if command -v docker >/dev/null 2>&1; then
        echo
        echo -e "${BLUE}Docker resources to be removed:${NC}"
        
        # Check containers
        local containers
        containers=$(docker ps -a --filter "ancestor=${DOCKER_IMAGE}" --format "{{.Names}}" 2>/dev/null | wc -l)
        if [[ "$containers" -gt 0 ]]; then
            echo "  - $containers Claude Sandbox container(s)"
        fi
        
        # Check image
        if docker image inspect "${DOCKER_IMAGE}" &> /dev/null; then
            local image_size
            image_size=$(docker images "${DOCKER_IMAGE}" --format "{{.Size}}" 2>/dev/null || echo "Unknown")
            echo "  - Docker image: ${DOCKER_IMAGE} (Size: $image_size)"
        fi
    fi
    
    echo
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  • The claude-sandbox command"
    echo "  • All Claude Sandbox Docker containers"
    echo "  • The Claude Sandbox Docker image"
    echo
    echo -e "${RED}This action cannot be undone!${NC}"
    echo
    echo -e "${YELLOW}Do you want to proceed with uninstallation?${NC}"
    echo "  [y] Yes, uninstall everything"
    echo "  [n] No, cancel uninstallation"
    echo
    
    while true; do
        read -p "Choice [y/n]: " choice
        case "$choice" in
            [Yy]|[Yy][Ee][Ss])
                echo
                log_info "Proceeding with uninstallation..."
                return 0
                ;;
            [Nn]|[Nn][Oo])
                echo
                return 1
                ;;
            *)
                echo "Please answer y (yes) or n (no)."
                ;;
        esac
    done
}

# Remove installed command
remove_command() {
    local target_script="$INSTALL_DIR/$SCRIPT_NAME"
    
    if [[ -f "$target_script" ]]; then
        rm -f "$target_script"
        log_info "Removed $target_script"
    fi
}