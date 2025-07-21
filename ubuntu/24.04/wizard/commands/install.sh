#!/usr/bin/env bash
# Install command for claude-sandbox wizard

# Load common functions
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Install command implementation
command_install() {
    local plugins=""
    
    # Parse install-specific arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --plugins)
                if [[ -z "${2:-}" ]]; then
                    log_error "--plugins requires a value"
                    exit 1
                fi
                plugins="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option for install command: $1"
                exit 1
                ;;
        esac
    done
    
    echo "🐳 Claude Sandbox Installation"
    echo "=========================="
    echo ""
    
    if [[ -n "$plugins" ]]; then
        log_info "Plugins to install: $plugins"
    else
        log_info "Using default configuration (nodejs only)"
    fi
    echo ""
    
    check_privileges
    check_prerequisites
    install_command
    generate_plugin_setup_script "$plugins"
    build_docker_image
    show_install_summary
}

# Execute if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    command_install "$@"
fi