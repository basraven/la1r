#!/bin/bash
set -e

echo "Installing desktop packages and development tools..."
apt-get update
apt-get install -y \
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
    python3-setuptools \
    openssh-client \
    sshpass \
    sudo \
    xz-utils

echo "Setting up noVNC..."
ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Create basraven user with uid 1000 (matching openvscode-server and claudecodeui)
if ! id basraven &> /dev/null; then
  if id -un 1000 &> /dev/null 2>&1; then
    # Rename existing uid-1000 user to basraven (without -m since /home/basraven exists on PVC)
    usermod -l basraven -d /home/basraven "$(id -un 1000)"
  else
    # Create basraven user fresh (skip -m if home already exists on PVC)
    if [ -d /home/basraven ]; then
      useradd -u 1000 -d /home/basraven -M -s /bin/bash basraven
    else
      useradd -u 1000 -d /home/basraven -m -s /bin/bash basraven
    fi
  fi
fi
echo "basraven ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/basraven

# --- Development tools (matching claudecodeui) ---
set +e  # Non-critical: don't abort desktop startup if a tool fails

# Install Node.js from official binary (avoids 1200+ deb packages from Ubuntu repos)
if ! command -v node &> /dev/null; then
  echo "Installing Node.js..."
  NODE_DIST_URL=$(curl -sL -o /dev/null -w '%{url_effective}' https://nodejs.org/dist/latest-v22.x/)
  NODE_VERSION=$(echo "$NODE_DIST_URL" | rev | cut -d/ -f2 | rev)
  if [ -n "$NODE_VERSION" ] && curl -fsSL "https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz; then
    tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1
    rm -f /tmp/node.tar.xz
    echo "Node.js ${NODE_VERSION} installed"
  else
    echo "Node.js download failed, skipping npm-based tools"
  fi
fi

# Configure npm to install globals to PVC-backed home so they survive restarts
if command -v npm &> /dev/null; then
  export NPM_CONFIG_PREFIX="$HOME/.npm-global"
  export PATH="$HOME/.npm-global/bin:$PATH"
  echo 'export PATH="$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Mark all directories as safe for Git
git config --global --add safe.directory '*'

# Install kubectl if not already installed
if ! command -v kubectl &> /dev/null; then
  echo "Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && chmod +x kubectl && mv kubectl /usr/local/bin/
else
  echo "kubectl already installed"
fi

# Install ansible if not already installed
if ! command -v ansible &> /dev/null; then
  echo "Installing ansible..."
  pip3 install --break-system-packages ansible
else
  echo "ansible already installed"
fi

# Install cloudcli if not already installed
if ! command -v cloudcli &> /dev/null; then
  npm install -g @cloudcli-ai/cloudcli --unsafe-perm
fi

# Install task-master-ai globally
if ! command -v task &> /dev/null; then
  npm install -g task-master-ai --unsafe-perm
fi

# Install Claude Code CLI using official bash install script
if ! command -v claude &> /dev/null; then
  echo "Installing Claude Code CLI..."
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
else
  echo "Claude Code CLI already installed"
fi

# Install Windsurf IDE
if ! command -v windsurf &> /dev/null; then
  echo "Installing Windsurf IDE..."
  WINDSURF_URL="https://windsurf-stable.codeium.com/api/update/download-linux-x64/latest"
  if curl -fsSL "$WINDSURF_URL" -o /tmp/windsurf.tar.gz; then
    tar -xzf /tmp/windsurf.tar.gz -C /opt/ 2>/dev/null || true
    WINDSURF_BIN=$(find /opt/Windsurf -name "windsurf" -type f 2>/dev/null | head -1)
    if [ -n "$WINDSURF_BIN" ]; then
      ln -sf "$WINDSURF_BIN" /usr/local/bin/windsurf
      echo "Windsurf IDE installed successfully"
    else
      echo "Windsurf binary not found in extracted archive"
    fi
    rm -f /tmp/windsurf.tar.gz
  else
    echo "Windsurf download failed, continuing..."
  fi
else
  echo "Windsurf IDE already installed"
fi

set -e  # Back to abort-on-error for desktop startup

echo "Cleaning up apt cache..."
rm -rf /var/lib/apt/lists/*

echo "Starting Xvfb on display :1..."
Xvfb :1 -screen 0 ${RESOLUTION} &
sleep 1

echo "Starting XFCE Desktop with D-Bus..."
dbus-run-session startxfce4 &
sleep 1

echo "Starting x11vnc server on port 5900..."
x11vnc -forever -shared -display :1 -rfbport 5900 -nopw &
sleep 1

echo "Starting noVNC web proxy on port 6080..."
exec websockify --web /usr/share/novnc 6080 localhost:5900
