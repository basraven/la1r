FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3-dev \
    build-essential \
    g++ \
    make \
    python3-setuptools \
    python3-pip \
    openssh-client \
    sshpass \
    curl \
    sudo \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install ansible
RUN pip3 install --break-system-packages ansible

# Install AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp/ && \
    /tmp/aws/install --update && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Install the tools that /install-tools.sh otherwise installs at every pod boot.
# install_* in that shared script early-returns when the tool is present, so baking
# gh/jq/yq/windsurf in here turns the startup install into an instant no-op.
# ffmpeg is here too: not installed by the shared script, and otherwise only apt-installed
# by hand inside a running container (lost on restart).
# Keyrings + apt sources for gh and windsurf (verbatim from common/install-tools.sh)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list && \
    curl -fsSL https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg \
      | gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" \
      > /etc/apt/sources.list.d/windsurf.list

# One apt-get update for both new sources; windsurf failure is tolerated like at runtime
RUN apt-get update -qq && \
    apt-get install -y -qq jq gh ffmpeg && \
    (apt-get install -y -qq windsurf || echo "WARNING: windsurf install failed") && \
    rm -rf /var/lib/apt/lists/*

# yq (mikefarah/yq, Go version — verbatim URL pattern from common/install-tools.sh)
RUN YQ_VERSION=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep tag_name | cut -d'"' -f4) && \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64" \
      -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

# Install Node.js from official binary (avoids 1200+ deb packages from Ubuntu repos)
RUN NODE_DIST_URL=$(curl -sL -o /dev/null -w '%{url_effective}' https://nodejs.org/dist/latest-v22.x/) && \
    NODE_VERSION=$(echo "$NODE_DIST_URL" | rev | cut -d/ -f2 | rev) && \
    if [ -n "$NODE_VERSION" ]; then \
      curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz && \
      tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
      rm -f /tmp/node.tar.xz; \
    fi

# Install npm-based tools globally
RUN npm config set prefix /usr/local && \
    npm install -g @cloudcli-ai/cloudcli --unsafe-perm && \
    npm install -g task-master-ai --unsafe-perm && \
    npm install -g @anthropic-ai/claude-code --unsafe-perm && \
    npm install -g @openai/codex --unsafe-perm

# Mark all directories as safe for Git
RUN git config --global --add safe.directory '*'

ENV NPM_CONFIG_PREFIX=/home/basraven/.npm-global
ENV PATH=/home/basraven/.npm-global/bin:/usr/local/bin:/usr/bin:/bin

EXPOSE 3001
