# Use this Dockerfile as the Template for repo development containers

FROM debian:trixie-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    openssh-client \
    openssh-server \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:${PATH}"
RUN echo 'export PATH="/root/.local/bin:$PATH"' >> /root/.bashrc

# Install repo dependencies

# SSH server setup
RUN mkdir -p /var/run/sshd /root/.ssh && chmod 700 /root/.ssh

# Configure VSCode settings
RUN mkdir -p /root/.vscode-server/data/Machine && \
    echo '{"remote.SSH.forwardAgent":false,"git.terminalAuthentication":false}' \
    > /root/.vscode-server/data/Machine/settings.json

# Set up git aliases
RUN git config --global alias.st status && \
    git config --global alias.ch checkout && \
    git config --global alias.br branch && \
    git config --global alias.co commit && \
    git config --global alias.lg "log --oneline"

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]

WORKDIR /root