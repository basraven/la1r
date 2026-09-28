#!/bin/bash
set -e

# Ensure the basraven home directory exists (provided by the shared home PVC).
mkdir -p "$HOME"

# --- OpenCode Go credentials ------------------------------------------------
# The server reads provider credentials from ~/.local/share/opencode/auth.json.
# Merge the opencode-go API key in, preserving any other providers already stored
# on the shared home PVC (idempotent on every boot).
if [ -n "$OPENCODE_API_KEY" ]; then
  AUTH_FILE="$HOME/.local/share/opencode/auth.json"
  mkdir -p "$(dirname "$AUTH_FILE")"
  python3 - "$AUTH_FILE" "$OPENCODE_API_KEY" <<'PYEOF'
import json, os, sys

path, key = sys.argv[1], sys.argv[2]
data = {}
if os.path.exists(path) and os.path.getsize(path) > 0:
    try:
        with open(path) as f:
            data = json.load(f)
    except Exception:
        data = {}
data["opencode-go"] = {"type": "api", "key": key}
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF
  chmod 600 "$AUTH_FILE" 2>/dev/null || true
  echo "OpenCode Go credentials written to $AUTH_FILE"
else
  echo "WARNING: OPENCODE_API_KEY is not set; OpenCode Go will be unauthenticated"
fi

# --- OpenCode config --------------------------------------------------------
# Use a dedicated config dir so we do not clobber the v1 config that other
# deployments (claudecodeui) keep on the shared home PVC. Default model is the
# OpenCode Go catalog.
OC_CFG_DIR="${OPENCODE_CONFIG_DIR:-$HOME/.config/opencode-v2}"
OC_CFG="$OC_CFG_DIR/opencode.json"
mkdir -p "$OC_CFG_DIR"
cat > "$OC_CFG" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "model": "opencode-go/deepseek-v4-flash",
  "update": "disable"
}
EOF
echo "OpenCode config written to $OC_CFG"

# Work from the shared workspaces root so sessions can reach every repo on the PVC.
cd "$HOME/projects" 2>/dev/null || cd "$HOME"

echo "Starting opencode web server on 0.0.0.0:4096..."
exec opencode serve --hostname 0.0.0.0 --port 4096
