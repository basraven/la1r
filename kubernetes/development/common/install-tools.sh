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

# ---- jq ----
install_jq() {
  command -v jq &>/dev/null && return 0
  log "Installing jq..."
  apt-get install -y -qq jq
  log "jq installed: $(jq --version 2>/dev/null)"
}

# ---- yq (mikefarah/yq, Go version) ----
install_yq() {
  command -v yq &>/dev/null && return 0
  log "Installing yq..."
  local yq_version
  yq_version=$(curl -fsSL "https://api.github.com/repos/mikefarah/yq/releases/latest" | grep tag_name | cut -d'"' -f4)
  curl -fsSL "https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64" \
    -o /usr/local/bin/yq
  chmod +x /usr/local/bin/yq
  log "yq installed: $(yq --version 2>/dev/null)"
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

# ---- Playwright + Chromium (for CloudCLI's browser-use MCP) ----
# cloudcli ships only playwright-core, so `require('playwright')` fails and every
# browser session reports "Install Playwright and Chromium to use browser
# sessions." The v8 image bakes playwright + Chromium under /opt (outside the
# /home PVC, which shadows anything baked under /home), so the normal path here
# is to link those baked copies into the PVC's global node_modules and browser
# cache — instant and offline. Falls back to a real install if not baked.
install_playwright() {
  local pvc_nm="/home/basraven/.npm-global/lib/node_modules"
  local img_nm="/usr/local/lib/node_modules"
  local cache="$HOME/.cache/ms-playwright"

  # 1. npm package: make `playwright` resolvable from the PVC's cloudcli install.
  if [ -d "$img_nm/playwright" ]; then
    mkdir -p "$pvc_nm"
    [ -e "$pvc_nm/playwright" ] || ln -sfn "$img_nm/playwright" "$pvc_nm/playwright"
  elif [ ! -e "$pvc_nm/playwright" ]; then
    local ver
    ver=$(node -p "try{require('$pvc_nm/@cloudcli-ai/cloudcli/node_modules/playwright-core/package.json').version}catch(e){''}" 2>/dev/null || true)
    if [ -n "$ver" ]; then
      log "Installing playwright@$ver for CloudCLI browser-use..."
      npm install -g --unsafe-perm "playwright@$ver" >/dev/null 2>&1 || log "WARNING: playwright install failed"
    fi
  fi

  # 2. Browser binaries: link the baked /opt/ms-playwright set into the cache the
  #    runtime HOME expects, else fall back to downloading Chromium.
  if [ -d /opt/ms-playwright ]; then
    mkdir -p "$cache"
    local d b
    for d in /opt/ms-playwright/*/; do
      [ -e "$d" ] || continue
      b=$(basename "$d")
      [ -e "$cache/$b" ] || ln -sfn "$d" "$cache/$b"
    done
  elif [ -x "$HOME/.npm-global/bin/playwright" ]; then
    "$HOME/.npm-global/bin/playwright" install chromium >/dev/null 2>&1 || true
  fi
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
install_jq
install_yq
install_ansible
install_aws_cli
install_gh
install_windsurf
install_vscode
install_chrome
install_playwright

log "Installation check complete."
