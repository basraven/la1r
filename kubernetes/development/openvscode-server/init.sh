#!/bin/bash
set -e

# Runtime tooling hook
if [ -f /install-tools.sh ]; then
  bash /install-tools.sh
fi

# Set hostname
hostname devc
grep -qxF "127.0.0.1   localhost devc" /etc/hosts || \
  echo "127.0.0.1   localhost devc" >> /etc/hosts

ulimit -n 1048576

# Ensure basraven user exists (safety net — image should have it, but handles
# stale image:latest cache where the user was only created at build time)
if ! id basraven &> /dev/null 2>&1; then
  if id -un 1000 &> /dev/null 2>&1; then
    usermod -l basraven -d /home/basraven -m "$(id -un 1000)" 2>/dev/null || true
  fi
fi

# Run personal install script if it exists
if [ -f /home/basraven/code.bas.install.sh ]; then
  su basraven -c "/home/basraven/code.bas.install.sh"
fi

# Start openvscode-server as basraven user (sources deepseek.sh for Claude config)
exec su basraven -c "source /home/basraven/.claude/deepseek.sh && exec /home/.openvscode-server/bin/openvscode-server --host=0.0.0.0"
