#!/bin/bash
# Shared install-tools.sh — idempotent runtime installer for development tools.
# Mounted as a ConfigMap and called from init.sh in each deployment container.
# Installs tools only if they are missing, so it's safe to call on every start.

log() {
  echo "[install-tools] $*"
}

# ---- kubectl ----
install_kubectl() {
  command -v kubectl &>/dev/null && return 0
  log "Installing kubectl..."
  curl -fsSL "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o /usr/local/bin/kubectl
  chmod +x /usr/local/bin/kubectl
  log "kubectl installed: $(kubectl version --client --short 2>/dev/null | head -1)"
}

# ---- Ansible ----
install_ansible() {
  command -v ansible &>/dev/null && return 0
  log "Installing ansible..."
  pip3 install --break-system-packages ansible
  log "ansible installed: $(ansible --version 2>/dev/null | head -1)"
}

# ---- AWS CLI v2 ----
install_aws_cli() {
  command -v aws &>/dev/null && return 0
  log "Installing AWS CLI v2..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$tmp_dir/awscliv2.zip"
  unzip -q "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
  "$tmp_dir/aws/install" --update
  rm -rf "$tmp_dir"
  log "AWS CLI installed: $(aws --version 2>&1)"
}

# ---- Windsurf (via APT) ----
install_windsurf() {
  command -v windsurf &>/dev/null && return 0
  log "Installing Windsurf IDE via APT..."

  if [ ! -f /usr/share/keyrings/windsurf-stable-archive-keyring.gpg ]; then
    curl -fsSL https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/windsurf.gpg \
      | gpg --dearmor -o /usr/share/keyrings/windsurf-stable-archive-keyring.gpg 2>/dev/null
  fi

  if [ ! -f /etc/apt/sources.list.d/windsurf.list ]; then
    echo "deb [signed-by=/usr/share/keyrings/windsurf-stable-archive-keyring.gpg arch=amd64] https://windsurf-stable.codeiumdata.com/wVxQEIWkwPUEAGf3/apt stable main" \
      > /etc/apt/sources.list.d/windsurf.list
  fi

  apt-get update -qq
  apt-get install -y -qq windsurf 2>/dev/null || {
    log "WARNING: Windsurf APT install failed (build continues)"
    return 0
  }
  log "Windsurf installed: $(windsurf --version 2>/dev/null | head -1)"
}

# ---- GitHub CLI ----
install_gh() {
  command -v gh &>/dev/null && return 0
  log "Installing GitHub CLI..."

  if [ ! -f /usr/share/keyrings/githubcli-archive-keyring.gpg ]; then
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
      | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg 2>/dev/null
  fi

  if [ ! -f /etc/apt/sources.list.d/github-cli.list ]; then
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
      > /etc/apt/sources.list.d/github-cli.list
  fi

  apt-get update -qq
  apt-get install -y -qq gh
  log "GitHub CLI installed: $(gh --version 2>/dev/null | head -1)"
}

# ---- Google Chrome ----
install_chrome() {
  command -v google-chrome-stable &>/dev/null && return 0

  # Only install Chrome if a desktop environment is available
  if [ -z "$DISPLAY" ] && [ ! -d /usr/share/xfce4 ]; then
    log "Skipping Google Chrome: no desktop environment detected"
    return 0
  fi

  log "Installing Google Chrome..."

  if [ ! -f /usr/share/keyrings/google-chrome-keyring.gpg ]; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
      | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg 2>/dev/null
  fi

  if [ ! -f /etc/apt/sources.list.d/google-chrome.list ]; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
      > /etc/apt/sources.list.d/google-chrome.list
  fi

  apt-get update -qq
  apt-get install -y -qq google-chrome-stable
  log "Google Chrome installed: $(google-chrome-stable --version 2>/dev/null)"
}

# ---- VS Code (via APT) ----
install_vscode() {
  command -v code &>/dev/null && return 0

  # Only install VS Code if a desktop environment is available
  if [ -z "$DISPLAY" ] && [ ! -d /usr/share/xfce4 ]; then
    log "Skipping VS Code: no desktop environment detected"
    return 0
  fi

  log "Installing VS Code via APT..."

  if [ ! -f /usr/share/keyrings/microsoft-archive-keyring.gpg ]; then
    curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" \
      | gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg 2>/dev/null
  fi

  if [ ! -f /etc/apt/sources.list.d/vscode.list ]; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
      > /etc/apt/sources.list.d/vscode.list
  fi

  apt-get update -qq
  apt-get install -y -qq code
  log "VS Code installed: $(code --version 2>/dev/null | head -1)"
}

# =========================================================
# Main
# =========================================================
log "Starting installation check..."

install_kubectl
install_ansible
install_aws_cli
install_gh
install_windsurf
install_vscode
install_chrome

log "Installation check complete."
