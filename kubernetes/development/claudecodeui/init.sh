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

# Expose deepseek-v4-flash in CloudCLI's codex model picker. CloudCLI's
# codex-models.provider.js reads ~/.codex/models_cache.json and, when present,
# uses it instead of its built-in gpt-5.x fallback catalog — so we mirror that
# fallback catalog verbatim (keeping the gpt-5.4 default) and ADD deepseek-v4-flash
# as an additional, effort-less entry (so no reasoning_effort param is sent).
CODEX_MODELS="$HOME/.codex/models_cache.json"
if [ ! -s "$CODEX_MODELS" ] || ! grep -q 'deepseek-v4-flash' "$CODEX_MODELS" 2>/dev/null; then
  cat > "$CODEX_MODELS" <<'JSON'
{
  "models": [
    {
      "slug": "gpt-5.4",
      "display_name": "gpt-5.4",
      "priority": 1,
      "visibility": "list",
      "supported_in_api": true,
      "supported_reasoning_levels": [
        { "effort": "low" },
        { "effort": "medium" },
        { "effort": "high" },
        { "effort": "xhigh" }
      ],
      "default_reasoning_level": "medium"
    },
    {
      "slug": "gpt-5.5",
      "display_name": "gpt-5.5",
      "priority": 2,
      "visibility": "list",
      "supported_in_api": true,
      "supported_reasoning_levels": [
        { "effort": "low" },
        { "effort": "medium" },
        { "effort": "high" },
        { "effort": "xhigh" }
      ],
      "default_reasoning_level": "medium"
    },
    {
      "slug": "gpt-5.4-mini",
      "display_name": "gpt-5.4-mini",
      "priority": 3,
      "visibility": "list",
      "supported_in_api": true,
      "supported_reasoning_levels": [
        { "effort": "low" },
        { "effort": "medium" },
        { "effort": "high" },
        { "effort": "xhigh" }
      ],
      "default_reasoning_level": "medium"
    },
    {
      "slug": "deepseek-v4-flash",
      "display_name": "deepseek-v4-flash",
      "description": "DeepSeek V4 Flash via LiteLLM/DeepInfra",
      "priority": 4,
      "visibility": "list",
      "supported_in_api": true
    }
  ]
}
JSON
  echo "Codex models_cache written (deepseek-v4-flash added)."
fi

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
