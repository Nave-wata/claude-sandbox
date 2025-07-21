FROM node:24.4-slim

# Layer 1: Install basic packages required for asdf and development tools
RUN apt-get update && apt-get install -y \
    curl \
    git \
    wget \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Layer 2: Install asdf version manager
USER node
WORKDIR /home/node
RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf && \
    cd ~/.asdf && \
    git checkout 80fffd86853fbfcc31e6a52aee99f8ab3d5fae9f
ENV PATH="/home/node/.asdf/shims:/home/node/.asdf/bin:$PATH"

# Layer 3: Install Claude Code globally using system node (for now)
USER root
RUN npm install -g @anthropic-ai/claude-code

# Layer 4: Setup plugin installations (dynamic script will be copied here)
USER node
COPY --chmod=755 setup-plugins.sh /tmp/setup-plugins.sh
RUN bash /tmp/setup-plugins.sh

# Layer 5: Final workspace setup
USER root
WORKDIR /workspace
RUN chown node:node /workspace

USER node

# Set the default command
CMD ["bash"]
