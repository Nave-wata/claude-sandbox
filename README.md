# Claude Sandbox

A containerized sandbox environment for running Claude Code safely and consistently across different systems.

## Overview

Claude Sandbox provides a containerized environment that wraps Claude Code with isolated execution, consistent dependencies, and automatic directory mounting. It acts as a pure wrapper around the `claude` command - all arguments are passed through unchanged to Claude Code running in a containerized environment.

This ensures that Claude Code runs in a controlled environment while maintaining access to your current working directory and preserving the exact same command-line interface.

## Concept & Purpose

### Why Claude Sandbox?

- **Isolation**: Run Claude Code in a controlled container environment
- **Consistency**: Same runtime environment across different host systems
- **Safety**: Containerized execution provides an additional security layer
- **Portability**: Easy deployment across different machines and environments
- **Transparency**: Pure wrapper behavior maintains familiar Claude Code interface

### Design Principles

1. **Pure Wrapper**: No custom options or modifications to Claude Code behavior
2. **Transparent Operation**: All arguments pass through unchanged to Claude Code
3. **Directory Mounting**: Current working directory is automatically accessible
4. **Configuration Persistence**: Claude settings and authentication are preserved
5. **Multi-Platform Support**: Extensible structure for different operating systems

## Usage

The `claude-sandbox` command works exactly like the regular `claude` command:

```bash
# Start interactive Claude Code CLI (most common usage)
claude-sandbox

# Resume previous session
claude-sandbox --resume

# Start with specific model
claude-sandbox --model sonnet

# All Claude Code options work exactly the same
claude-sandbox --help      # Shows Claude Code help
claude-sandbox --version   # Shows Claude Code version
```

**Important**: `claude-sandbox` does not have its own help or options. Everything is passed through to the containerized Claude Code instance.

## How It Works

1. **Pure Wrapper**: The `claude-sandbox` command passes all arguments unchanged to containerized Claude Code
2. **Directory Mounting**: Your current working directory is automatically mounted into the container at `/workspace`
3. **Configuration Persistence**: Your Claude settings (`~/.claude/`, `~/.claude.json`) are mounted to preserve authentication and preferences
4. **Container Management**: A container image is built on first use and reused for subsequent runs
5. **Interactive CLI**: When run without arguments, it starts the full interactive Claude Code CLI in a container

## Project Structure

```
claude-sandbox/
├── README.md                           # This documentation (concept and general usage)
└── ubuntu/                             # OS-specific implementations
    └── 24.04/                          # Ubuntu 24.04 implementation
        ├── README.md                   # Implementation-specific documentation
        ├── wizard.sh                   # Setup and management wizard
        ├── claude-sandbox              # Main wrapper script
        └── sandbox/                    # Container configuration
            └── Dockerfile              # Container definition
```

This structure allows for future support of different operating systems and versions by adding new directories like `ubuntu/22.04/`, `alpine/3.18/`, etc.

## Available Implementations

### Ubuntu 24.04

A Docker-based implementation using Node.js 24.4-slim as the base image with asdf version manager support.

**Installation**: See [`ubuntu/24.04/README.md`](ubuntu/24.04/README.md) for detailed installation and usage instructions.

**Features**:
- Node.js environment with Claude Code pre-installed
- asdf version manager for multi-language development support
- Dynamic plugin configuration with `--plugins` option
- Automatic directory mounting
- Configuration persistence
- Security-hardened container setup with commit SHA verification
- Robust error handling and stable version preferences

## Optional Aliases

You can create aliases for convenience:

```bash
# Add to your ~/.bashrc
alias claude='claude-sandbox'    # Use as default claude command
alias cs='claude-sandbox'        # Short alias
```

## Requirements

- **Container Runtime**: Docker (for current implementations)
- **Permissions**: User must have container runtime access
- **Claude Code License**: Valid Claude Code authentication/license
