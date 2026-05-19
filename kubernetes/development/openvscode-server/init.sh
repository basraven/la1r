#!/bin/bash
set -e

# Rename UID 1000 to basraven if not already basraven
if ! id basraven &> /dev/null 2>&1; then
  if id -un 1000 &> /dev/null 2>&1; then
    usermod -l basraven -d /home/basraven "$(id -un 1000)" 2>/dev/null || true
  fi
fi

# Set passwordless sudo for the user
echo "basraven ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/basraven

ulimit -n 1048576

# Run personal install script if it exists
if [ -f /home/basraven/code.bas.install.sh ]; then
  su basraven -c "/home/basraven/code.bas.install.sh"
fi

# Start openvscode-server as basraven user
exec su basraven -c "/home/.openvscode-server/bin/openvscode-server --host=0.0.0.0"
