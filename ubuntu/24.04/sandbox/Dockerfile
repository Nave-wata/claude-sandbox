FROM node:24.4-slim

# Create workspace directory for mounting user projects
WORKDIR /workspace

# Install necessary packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Create node user home directory and ensure workspace permissions
RUN mkdir -p /home/node && chown node:node /home/node
RUN chown node:node /workspace

# Use the existing node user (UID 1000)
USER node

# Set the default command
CMD ["bash"]
