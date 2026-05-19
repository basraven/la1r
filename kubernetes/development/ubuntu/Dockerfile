FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install all apt packages (combining local/Dockerfile and init.sh)
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
    sshpass \
    sudo \
    xz-utils \
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

# Configure npm for global installs and install cloudcli + task-master-ai
RUN npm config set prefix /usr/local && \
    npm install -g @cloudcli-ai/cloudcli --unsafe-perm && \
    npm install -g task-master-ai --unsafe-perm

# Mark all directories as safe for Git
RUN git config --global --add safe.directory '*'

ENV DISPLAY=:1
ENV RESOLUTION=1280x800x24

EXPOSE 5900 6080
