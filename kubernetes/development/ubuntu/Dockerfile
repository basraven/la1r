FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install all apt packages
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    dbus-x11 \
    xvfb \
    x11vnc \
    novnc \
    websockify \
    net-tools \
    curl \
    git \
    papirus-icon-theme \
    python3-dev \
    build-essential \
    g++ \
    make \
    python3-pip \
    python3-setuptools \
    openssh-client \
    passwd \
    sshpass \
    sudo \
    xz-utils \
    unzip \
    gpg \
    && rm -rf /var/lib/apt/lists/*

# Clone Nordic GTK theme
RUN git clone --depth 1 https://github.com/EliverLara/Nordic.git /usr/share/themes/Nordic

# Create XFCE config files
RUN mkdir -p /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/ && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xsettings" version="1.0"><property name="Net" type="empty"><property name="ThemeName" type="string" value="Nordic"/><property name="IconThemeName" type="string" value="Papirus-Dark"/></property></channel>' > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml && \
    echo '<?xml version="1.0" encoding="UTF-8"?><channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="theme" type="string" value="Nordic"/></property></channel>' > /etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# Standard noVNC configuration link
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Install Node.js from official binary (avoids 1200+ deb packages from Ubuntu repos)
RUN NODE_DIST_URL=$(curl -sL -o /dev/null -w '%{url_effective}' https://nodejs.org/dist/latest-v22.x/) && \
    NODE_VERSION=$(echo "$NODE_DIST_URL" | rev | cut -d/ -f2 | rev) && \
    if [ -n "$NODE_VERSION" ]; then \
      curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz && \
      tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 && \
      rm -f /tmp/node.tar.xz; \
    fi

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x kubectl && mv kubectl /usr/local/bin/

# Install ansible
RUN pip3 install --break-system-packages ansible

# Install npm-based tools globally
RUN npm config set prefix /usr/local && \
    npm install -g @cloudcli-ai/cloudcli --unsafe-perm && \
    npm install -g task-master-ai --unsafe-perm && \
    npm install -g @anthropic-ai/claude-code --unsafe-perm

# Install Windsurf IDE (via official APT repo)
RUN curl -fsSL https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg \
      | gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg 2>/dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" \
      > /etc/apt/sources.list.d/windsurf.list && \
    apt-get update -qq && apt-get install -y -qq windsurf && \
    echo "Windsurf IDE installed"

# Install VS Code (via Microsoft APT repo)
RUN curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
      > /etc/apt/sources.list.d/vscode.list && \
    apt-get update -qq && apt-get install -y -qq code

# Install Google Chrome
RUN curl -fsSL "https://dl.google.com/linux/linux_signing_key.pub" \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update -qq && apt-get install -y -qq google-chrome-stable

# Install AWS CLI v2
RUN curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp/ && \
    /tmp/aws/install --update && \
    rm -rf /tmp/awscliv2.zip /tmp/aws

# Mark all directories as safe for Git
RUN git config --global --add safe.directory '*'

# Rename existing ubuntu user (UID 1000) to basraven for non-root desktop sessions
# Ubuntu 24.04 base image ships with an 'ubuntu' user at UID 1000
RUN usermod -l basraven ubuntu && \
    usermod -d /home/basraven -m basraven && \
    groupmod -n basraven ubuntu && \
    echo "basraven ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/basraven

ENV DISPLAY=:1
ENV RESOLUTION=1280x800x24
ENV NPM_CONFIG_PREFIX=/home/basraven/.npm-global
ENV PATH=/home/basraven/.npm-global/bin:/usr/local/bin:/usr/bin:/bin

EXPOSE 5900 6080
