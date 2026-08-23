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
# bwrap can't create namespaces in this pod (no CAP_SYS_ADMIN, userns blocked);
# run commands without the bubblewrap sandbox.
sandbox_mode = "danger-full-access"

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

# Ensure the bubblewrap-less sandbox mode is set even when merging into an
# existing config (top-level key; must stay above any table sections).
grep -q '^sandbox_mode[[:space:]]*=' "$CODEX_CFG" || sed -i '1isandbox_mode = "danger-full-access"\n' "$CODEX_CFG"

# Keep codex's DeepSeek model metadata capped for auto-compaction.
#
# Why this exists: litellm's model_info caps (max_input_tokens/max_output_tokens)
# are metadata-only — they are advertised via /v1/models but litellm does NOT
# clamp the client's requested max_output_tokens. codex 0.149.0 has no config or
# catalog key for a max output cap, and requests max_output_tokens=384000 by
# default. DeepSeek's real context limit is 1,048,576 tokens, so a request with
# input >= 664,577 tokens overflows (664577 + 384000 = 1048577) and deepinfra
# rejects mid-stream -> codex "stream closed before response.completed".
#
# The knob codex DOES honor is auto_compact_token_limit in its model catalog:
# lowering it to 600000 makes codex compact conversation history before a
# request can overflow (600k input + 384k output = 984k < 1,048,576).
CODEX_CATALOG_DIR="$HOME/.codex/model-catalogs"
CODEX_CATALOG="$CODEX_CATALOG_DIR/models.json"
ensure_codex_catalog() {
  mkdir -p "$CODEX_CATALOG_DIR"
  if [ ! -f "$CODEX_CATALOG" ]; then
    cat > "$CODEX_CATALOG" <<'JSON'
{
  "models": [
    {
      "slug": "deepseek-v4-flash",
      "display_name": "deepseek-v4-flash",
      "description": "DeepSeek V4 Flash via LiteLLM/DeepInfra",
      "supported_reasoning_levels": [],
      "shell_type": "unified_exec",
      "visibility": "list",
      "supported_in_api": true,
      "priority": 1,
      "additional_speed_tiers": [],
      "service_tiers": [],
      "support_verbosity": false,
      "experimental_supported_tools": [],
      "context_window": 1000000,
      "max_context_window": 1000000,
      "auto_compact_token_limit": 600000,
      "truncation_policy": {
        "mode": "bytes",
        "limit": 10000
      },
      "model_messages": {
        "instructions_template": "You are a helpful coding agent. Reply concisely."
      }
    }
  ]
}
JSON
    echo "Codex deepseek model catalog written (auto_compact_token_limit=600000)."
  else
    python3 - "$CODEX_CATALOG" <<'PYEOF'
import json, sys
path = sys.argv[1]
with open(path) as f:
    data = json.load(f)
changed = False
for m in data.get("models", []):
    if m.get("slug") == "deepseek-v4-flash":
        if m.get("auto_compact_token_limit") != 600000:
            m["auto_compact_token_limit"] = 600000
            changed = True
if changed:
    with open(path, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")
    print("Codex deepseek catalog auto_compact_token_limit set to 600000.")
else:
    print("Codex deepseek catalog already capped at 600000.")
PYEOF
  fi
  # Point config.toml at the catalog (top-level key; must stay above tables).
  grep -q '^model_catalog_json[[:space:]]*=' "$CODEX_CFG" || \
    sed -i '1imodel_catalog_json = "'"$CODEX_CATALOG"'"\n' "$CODEX_CFG"
}
ensure_codex_catalog

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

# CloudCLI's codex model picker uses the gpt-5.x built-in fallback; litellm
# aliases those names to deepseek-v4-flash (see litellm config.yaml), so any
# model codex requests routes to deepseek — no per-model picker cache needed.
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
