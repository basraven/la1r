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

# Configure Codex CLI for LiteLLM/DeepInfra (idempotent; persists on PVC).
# A pre-existing config (e.g. the cloudcli MCP block) on the PVC must NOT be
# clobbered — merge the LiteLLM provider in instead.
mkdir -p "$HOME/.codex"
CODEX_CFG="$HOME/.codex/config.toml"
if [ ! -f "$CODEX_CFG" ]; then
  cat > "$CODEX_CFG" <<'EOF'
model = "deepseek-v4-flash"
model_provider = "litellm"

[model_providers.litellm]
name = "LiteLLM (DeepInfra)"
base_url = "http://litellm/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"
requires_openai_auth = false
EOF
  echo "Codex configured for LiteLLM/DeepInfra."
elif ! grep -q '^model_provider[[:space:]]*=[[:space:]]*"litellm"' "$CODEX_CFG"; then
  # Existing config present but not pointed at litellm — add top-level model keys
  # (unless the user already pinned a different model) and append the provider table.
  grep -q '^model_provider[[:space:]]*=' "$CODEX_CFG" || \
    sed -i '1imodel = "deepseek-v4-flash"\nmodel_provider = "litellm"\n' "$CODEX_CFG"
  cat >> "$CODEX_CFG" <<'EOF'

[model_providers.litellm]
name = "LiteLLM (DeepInfra)"
base_url = "http://litellm/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"
requires_openai_auth = false
EOF
  echo "Codex LiteLLM provider merged into existing config."
else
  echo "Codex already configured for LiteLLM."
fi

# Ensure Codex has a credential so CloudCLI reports the provider as "connected".
# Codex routes through litellm via config.toml (env_key LITELLM_API_KEY); this
# auth.json OPENAI_API_KEY entry is what CloudCLI's status check reads.
if [ -n "$LITELLM_API_KEY" ]; then
  CODEX_AUTH="$HOME/.codex/auth.json"
  if [ ! -s "$CODEX_AUTH" ] || ! grep -q '"OPENAI_API_KEY"' "$CODEX_AUTH" 2>/dev/null; then
    printf '{\n  "OPENAI_API_KEY": "%s"\n}\n' "$LITELLM_API_KEY" > "$CODEX_AUTH"
    chmod 600 "$CODEX_AUTH"
    echo "Codex auth.json written (OPENAI_API_KEY)."
  fi
fi

# Expose deepseek-v4-flash in CloudCLI's codex model picker. The cache file
# (~/.codex/models_cache.json) is codex's own cache: CloudCLI reads it for the
# model picker, and codex reads it for model metadata. codex/CloudCLI updates may
# rewrite it, so on every start we re-ensure deepseek-v4-flash is present —
# additively, without removing any other models an update may have added.
python3 - "$HOME/.codex/models_cache.json" <<'PY'
import json, os, sys

path = sys.argv[1]
os.makedirs(os.path.dirname(path), exist_ok=True)
ENTRY = {
    "slug": "deepseek-v4-flash",
    "display_name": "deepseek-v4-flash",
    "description": "DeepSeek V4 Flash via LiteLLM/DeepInfra",
    "supported_reasoning_levels": [],
    "shell_type": "unified_exec",
    "visibility": "list",
    "supported_in_api": True,
    "priority": 1,
    "support_verbosity": False,
    "truncation_policy": {"mode": "bytes", "limit": 10000},
    "experimental_supported_tools": [],
    "context_window": 1000000,
    "max_context_window": 1000000,
    "auto_compact_token_limit": 950000,
    "model_messages": {"instructions_template": "You are a helpful coding agent. Reply concisely."},
}
try:
    with open(path) as f:
        data = json.load(f)
    if not isinstance(data, dict) or not isinstance(data.get("models"), list):
        data = {"models": []}
except (OSError, ValueError):
    data = {"fetched_at": "1970-01-01T00:00:00Z", "client_version": "0.149.0", "models": []}
if not any(isinstance(m, dict) and m.get("slug") == "deepseek-v4-flash" for m in data["models"]):
    data["models"].append(ENTRY)
    data.setdefault("fetched_at", "1970-01-01T00:00:00Z")
    data.setdefault("client_version", "0.149.0")
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Codex models_cache: deepseek-v4-flash ensured.")
else:
    print("Codex models_cache already has deepseek-v4-flash.")
PY

cd /home/basraven/projects/la1r

# # Initialize TaskMaster AI if not already set up (persists on PVC)
# if [ ! -d ".taskmaster" ]; then
#   echo "Initializing TaskMaster AI..."
#   task-master init --yes
# else
#   echo "TaskMaster AI already initialized."
# fi

echo "Trying to start cloudcli..."
if cloudcli start --port 3001; then
  echo "Started with 'cloudcli start --port 3001'"
elif cloudcli --port 3001; then
  echo "Started with 'cloudcli --port 3001'"
else
  echo "Starting fallback HTTP server on port 3001"
  python3 -m http.server 3001
fi
