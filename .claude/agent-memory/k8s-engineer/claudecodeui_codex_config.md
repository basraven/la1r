---
name: claudecodeui-codex-config
description: claudecodeui pod's ~/.codex/config.toml is PVC-persisted; init.sh now MERGES the litellm provider into existing configs (v5+), and pod shows Ready before init.sh finishes — wait ~2min before exec'ing config checks
metadata:
  type: project
---

The `claudecodeui` deployment (namespace `development`) routes the OpenAI Codex CLI through LiteLLM → DeepInfra (`model_provider = "litellm"`, `base_url = "http://litellm/v1"`, `wire_api = "responses"`, model `deepseek-v4-flash`).

**Fix applied 2026-08-22 (image `claudecodeui:v5`, ConfigMap `claudecodeui-init`):** `init.sh` no longer only writes a fresh config when the file is absent. It now MERGES the litellm provider into a pre-existing `~/.codex/config.toml`:
- If file absent → write fresh config with litellm provider.
- Elif file present but `model_provider != "litellm"` → `sed -i '1i...'` top-level `model = "deepseek-v4-flash"` / `model_provider = "litellm"`, then append `[model_providers.litellm]` table (`base_url http://litellm/v1`, `env_key LITELLM_API_KEY`, `wire_api responses`, `requires_openai_auth false`).
- Else → already configured, no-op.

**Key verification gotcha:** the Deployment has NO readiness probe, so a pod reports `1/1 Ready` the moment the container starts — but init.sh (install-tools → codex merge → cloudcli start) takes 1-2+ minutes to finish. Exec'ing `cat ~/.codex/config.toml` right after rollout can catch the STALE pre-merge config (only the `[mcp_servers.cloudcli-browser]` block) and falsely suggest the fix failed. Wait until config.toml mtime updates (grep pod logs for `Codex LiteLLM provider merged into existing config.` / `Codex configured for LiteLLM/DeepInfra.`) before trusting the file. ConfigMap is static (`disableNameSuffixHash`) so a ConfigMap change requires `kubectl rollout restart deployment/claudecodeui -n development`.

**Expected good config.toml** (both blocks + top-level keys):
```
model = "deepseek-v4-flash"
model_provider = "litellm"
[mcp_servers.cloudcli-browser] ... (cloudcli's own block)
[model_providers.litellm] base_url=http://litellm/v1, wire_api=responses, env_key=LITELLM_API_KEY
```

**litellm evidence for codex:** codex with `wire_api = "responses"` hits `POST /v1/responses` on the litellm service; success shows in litellm access logs as `"POST /v1/responses HTTP/1.1" 200 OK` from the claudecodeui pod IP. A pre-existing unrelated error exists: `POST /v1/messages` → 500 `TypeError: anthropic_messages() missing 1 required positional argument: 'messages'` (litellm proxy bug on the Anthropic endpoint; do not confuse with codex routing). codex prints a benign warning: `Model metadata for 'deepseek-v4-flash' not found. Defaulting to fallback metadata`.

Claude Code (claude CLI) routing is separate and goes **direct** to DeepSeek: `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic` (in pod env AND `~/.claude/settings.json`); cloudcli UI listens on 3001 (Express, HTTP 200 on `/`).
