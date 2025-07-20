# Claude Sandbox - Ubuntu 24.04 Implementation

This directory contains the Ubuntu 24.04 implementation of Claude Sandbox, providing a containerized environment for running Claude Code.

## Installation

### Prerequisites

- **Docker**: Must be installed and running
- **Permissions**: User must have Docker access (be in `docker` group or use sudo)
- **Claude Code License**: Valid Claude Code authentication/license

### Install Claude Sandbox

1. **Navigate to this directory:**
   ```bash
   cd ubuntu/24.04
   ```

2. **Run the setup wizard:**
   ```bash
   # Default user-local installation (no sudo required)
   ./wizard.sh
   
   # Optional: System-wide installation (requires sudo)
   sudo ./wizard.sh
   ```

3. **Verify installation:**
   ```bash
   claude-sandbox --help    # This shows Claude Code help, not claude-sandbox help
   ```

## Usage

The `claude-sandbox` command works exactly like the regular `claude` command, but runs in a containerized environment:

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

## Optional Aliases

You can create aliases for convenience:

```bash
# Add to your ~/.bashrc
alias claude='claude-sandbox'    # Use as default claude command
alias cs='claude-sandbox'        # Short alias
```

## Implementation Details

### Container Environment

This implementation uses:
- **Base Image**: `node:24.4-slim`
- **Working Directory**: `/workspace` (mounted from current directory)
- **User**: `node` (UID 1000)
- **Package Manager**: npm (for Claude Code installation)

### Directory Structure

```
ubuntu/24.04/
├── README.md                   # This documentation
├── wizard.sh                   # Setup and management wizard
├── claude-sandbox              # Main wrapper script
└── sandbox/                    # Container configuration
    └── Dockerfile              # Container definition
```

### How It Works

1. **Interactive CLI**: When you run `claude-sandbox` without arguments, it starts the full interactive Claude Code CLI in a container
2. **Directory Mounting**: Your current working directory is automatically mounted into the container at `/workspace`
3. **Configuration Persistence**: Your Claude settings (`~/.claude/`, `~/.claude.json`) are mounted to preserve authentication and preferences
4. **Container Management**: A Docker image is built on first use and reused for subsequent runs

## Advanced Configuration

### Container Customization

The Docker container is pre-configured with Node.js 24.4 and Claude Code. The container environment can be customized by modifying the `sandbox/Dockerfile` to install additional tools or configure the environment as needed.

## Troubleshooting

### Docker Permission Issues

If you get permission errors:

```bash
# Add your user to the docker group
sudo usermod -aG docker $USER
# Log out and back in, or run:
newgrp docker
```

### Container Build Issues

Force rebuild the container:

```bash
# Remove existing image
docker rmi claude-sandbox
# Run claude-sandbox again to rebuild
claude-sandbox --help
```

### PATH Issues (User Installation)

If `claude-sandbox` command is not found after user installation:

```bash
# Add to your shell profile (~/.bashrc)
export PATH="$HOME/.local/bin:$PATH"
# Reload your shell
source ~/.bashrc
```

## Uninstallation

To remove Claude Sandbox:

```bash
./wizard.sh --uninstall
```

This removes:
- The installed `claude-sandbox` command
- Project references and symlinks  
- All Docker containers using the claude-sandbox image
- The claude-sandbox Docker image itself
- Preserves your Claude configuration files

## Technical Notes

### Container Specifications

- **Image Name**: `claude-sandbox`
- **Container Name**: `claude-sandbox-{UID}` (unique per user)
- **Networking**: Host network (inherits from host)
- **Storage**: Ephemeral containers (removed after each run)

### Volume Mounts

- Current working directory → `/workspace`
- `~/.claude` → `/home/node/.claude`
- `~/.claude.json` → `/home/node/.claude.json`

### Security Considerations

- Containers run as non-root user (`node`, UID 1000)
- No privileged access required
- Containers are ephemeral and removed after each run
- Only current directory and Claude config are mounted