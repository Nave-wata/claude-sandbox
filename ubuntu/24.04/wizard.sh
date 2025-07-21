#!/usr/bin/env bash
# Claude Sandbox Wizard
# Main dispatcher script for managing claude-sandbox installation

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load common functions
source "$SCRIPT_DIR/wizard/lib/common.sh"

# Show usage
show_usage() {
    cat << EOF
Claude Sandbox Setup Wizard

USAGE:
    ./wizard.sh <command> [options]

COMMANDS:
    install                 Install claude-sandbox with optional plugin configuration
    uninstall               Uninstall claude-sandbox and clean up resources
    help                    Show this help message

OPTIONS FOR INSTALL:
    --plugins PLUGINS       Comma-separated list of asdf plugins to install
                           (e.g., --plugins uv,cmake,java)

GLOBAL OPTIONS:
    --help, -h              Show this help message

DESCRIPTION:
    This wizard manages installation and uninstallation of the claude-sandbox
    command which provides a containerized Claude Code environment with the
    current directory mounted as the working space.
    
    NOTE: If claude-sandbox is already installed, the wizard will detect it
    and ask for confirmation before reinstalling (command + Docker image).

INSTALLATION:
    - System-wide (requires sudo): /usr/local/bin/claude-sandbox
    - User install: ~/.local/bin/claude-sandbox

EXAMPLES:
    ./wizard.sh install                          # Install with default configuration
    ./wizard.sh install --plugins uv             # Install with Python/uv support
    ./wizard.sh install --plugins uv,cmake,java  # Install with multiple language support
    ./wizard.sh uninstall                        # Uninstall claude-sandbox
    ./wizard.sh help                             # Show help

EOF
}

# Command dispatcher
dispatch_command() {
    local command="$1"
    shift
    
    case "$command" in
        install)
            source "$SCRIPT_DIR/wizard/commands/install.sh"
            command_install "$@"
            ;;
        uninstall)
            source "$SCRIPT_DIR/wizard/commands/uninstall.sh"
            command_uninstall "$@"
            ;;
        help)
            show_usage
            ;;
        *)
            log_error "Unknown command: $command"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Main function
main() {
    # Handle global options and command dispatching
    if [[ $# -eq 0 ]]; then
        log_error "No command specified"
        echo ""
        show_usage
        exit 1
    fi
    
    # Handle global options first
    case "$1" in
        --help|-h)
            show_usage
            exit 0
            ;;
        help|install|uninstall)
            dispatch_command "$@"
            ;;
        *)
            log_error "Unknown command or option: $1"
            echo ""
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
