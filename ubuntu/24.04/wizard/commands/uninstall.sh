#!/usr/bin/env bash
# Uninstall command for claude-sandbox wizard

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Uninstall command implementation
command_uninstall() {
    # Parse uninstall-specific arguments (currently none, but ready for expansion)
    while [[ $# -gt 0 ]]; do
        case $1 in
            *)
                log_error "Unknown option for uninstall command: $1"
                exit 1
                ;;
        esac
    done
    
    echo "🗑️  Claude Sandbox Uninstallation"
    echo "=========================="
    echo ""
    
    check_privileges
    cleanup_docker
    remove_command
    
    log_info "Claude Sandbox uninstalled successfully"
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command_uninstall "$@"
fi