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
    npm install -g @anthropic-ai/claude-code --unsafe-perm

# Mark all directories as safe for Git
RUN git config --global --add safe.directory '*'

ENV NPM_CONFIG_PREFIX=/home/basraven/.npm-global
ENV PATH=/home/basraven/.npm-global/bin:/usr/local/bin:/usr/bin:/bin

EXPOSE 3001
