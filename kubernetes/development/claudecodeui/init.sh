#!/bin/bash
set -e

# Install missing development tools
if [ -f /install-tools.sh ]; then
  bash /install-tools.sh
fi

# Rebuild native addons for plugins (node-pty linux-x64 prebuild missing when installed with --ignore-scripts)
echo "Rebuilding native addons for plugins..."
PLUGIN_DIR="$HOME/.claude-code-ui/plugins"
if [ -d "$PLUGIN_DIR" ]; then
  for plugin in "$PLUGIN_DIR"/*/; do
    if [ -f "${plugin}package.json" ]; then
      echo "Rebuilding native addons in $(basename "$plugin")..."
      (cd "$plugin" && npm rebuild 2>/dev/null) || true
    fi
  done
fi

cd /home/basraven/projects/la1r

echo "Trying to start cloudcli..."
if cloudcli start --port 3001; then
  echo "Started with 'cloudcli start --port 3001'"
elif cloudcli --port 3001; then
  echo "Started with 'cloudcli --port 3001'"
else
  echo "Starting fallback HTTP server on port 3001"
  python3 -m http.server 3001
fi
