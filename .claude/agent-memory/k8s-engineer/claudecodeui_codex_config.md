---
name: claudecodeui-codex-config
description: claudecodeui pod's ~/.codex/config.toml is PVC-persisted; init.sh now MERGES the litellm provider into existing configs (v5+), and pod shows Ready before init.sh finishes — wait ~2min before exec'ing config checks; gpt-5.x→deepseek rewrite needs BOTH virtual-key scope (403 fix) AND router_settings.model_group_alias (litellm_settings.aliases is INERT in 1.96.2)
metadata:
  type: project
---

The `claudecodeui` deployment (namespace `development`) routes the OpenAI Codex CLI through LiteLLM → DeepInfra (`model_provider = "litellm"`, `base_url = "http://litellm/v1"`, `wire_api = "responses"`, model `deepseek-v4-flash`).

**DeepInfra param fix applied 2026-08-22 (litellm, `kubernetes/development/litellm/config.yaml`):** codex sends `parallel_tool_calls`/`reasoning_effort`, which DeepInfra rejects → litellm 400 `UnsupportedParamsError`. Fixed via `litellm_settings: drop_params: true`. Verified: after `kubectl apply -k .../litellm/` + `kubectl rollout restart deploy/litellm -n development`, codex exec returned `OK` (model deepseek-v4-flash, provider litellm), litellm logged `"POST /v1/responses" 200 OK`, no UnsupportedParamsError/400. Benign litellm warnings: "Dropping Responses API tool of type 'namespace'" (the drop_params drop working) and "Container ownership recording skipped on streaming /v1/responses". codex may print transient `ERROR: Reconnecting... waiting for network` lines while still succeeding (litellm recorded only ONE 200 request for the whole exchange).

**Fix applied 2026-08-22 (image `claudecodeui:v5`, ConfigMap `claudecodeui-init`):** `init.sh` no longer only writes a fresh config when the file is absent. It now MERGES the litellm provider into a pre-existing `~/.codex/config.toml`:
- If file absent → write fresh config with litellm provider.
- Elif file present but `model_provider != "litellm"` → `sed -i '1i...'` top-level `model = "deepseek-v4-flash"` / `model_provider = "litellm"`, then append `[model_providers.litellm]` table (`base_url http://litellm/v1`, `env_key LITELLM_API_KEY`, `wire_api responses`, `requires_openai_auth false`).
- Else → already configured, no-op.

**Key verification gotcha:** the Deployment has NO readiness probe, so a pod reports `1/1 Ready` the moment the container starts — but init.sh (install-tools → codex merge → cloudcli start) takes 1-2+ minutes to finish. Exec'ing `cat ~/.codex/config.toml` right after rollout can catch the STALE pre-merge config (only the `[mcp_servers.cloudcli-browser]` block) and falsely suggest the fix failed. Wait until config.toml mtime updates (grep pod logs for the codex markers) before trusting the file. ConfigMap is static (`disableNameSuffixHash`) so a ConfigMap change requires `kubectl rollout restart deployment/claudecodeui -n development`.

**Exact init.sh markers (from `kubernetes/development/claudecodeui/init.sh`):**
- Fresh config: `Codex configured for LiteLLM/DeepInfra.`
- Merged into existing: `Codex LiteLLM provider merged into existing config.`
- No-op (already configured): `Codex already configured for LiteLLM.` ← observed when PVC already has litellm
- auth.json only written if absent: `Codex auth.json written (OPENAI_API_KEY).` — absent from log means it was already on PVC (do NOT read absence as failure)
- models_cache/provider-models-cache handling **REMOVED from init.sh (2026-08-22)** — the `~/.codex/models_cache.json` and `~/.cloudcli/provider-models-cache.json` rewrite blocks are gone; the litellm `router_settings.model_group_alias` (gpt-5.x→deepseek-v4-flash) makes the per-model picker cache unnecessary. `init.sh` is now only install-tools → native-addon rebuild → codex config.toml merge → auth.json → cloudcli start. Sync `claudecodeui-init` to the live cluster with `kubectl apply -k .../claudecodeui/` (configmap `configured`).

**Expected good config.toml** (both blocks + top-level keys):
```
model = "deepseek-v4-flash"
model_provider = "litellm"
[mcp_servers.cloudcli-browser] ... (cloudcli's own block)
[model_providers.litellm] base_url=http://litellm/v1, wire_api=responses, env_key=LITELLM_API_KEY
```

**litellm evidence for codex:** codex with `wire_api = "responses"` hits `POST /v1/responses` on the litellm service; success shows in litellm access logs as `"POST /v1/responses HTTP/1.1" 200 OK` from the claudecodeui pod IP. A pre-existing unrelated error exists: `POST /v1/messages` → 500 `TypeError: anthropic_messages() missing 1 required positional argument: 'messages'` (litellm proxy bug on the Anthropic endpoint; do not confuse with codex routing). codex prints a benign warning: `Model metadata for 'deepseek-v4-flash' not found. Defaulting to fallback metadata`.

Claude Code (claude CLI) routing is separate and goes **direct** to DeepSeek: `ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic` (in pod env AND `~/.claude/settings.json`); cloudcli UI listens on 3001 (Express, HTTP 200 on `/`).

**gpt-5.x → deepseek rewrite needs TWO changes (both verified 2026-08-22):** codex sometimes requests `gpt-5.x` (stale sessions / built-in model list). The rewrite is a 2-stage problem:
1. **Key scope (auth):** the virtual key (`$LITELLM_API_KEY` in the claudecodeui pod, Secret `litellm-virtual-key`/`LITELLM_API_KEY`, ns `development`) was scoped to `['deepseek-v4-flash']`. The auth check runs on the RAW requested name BEFORE routing, so `model: gpt-5.5` → **403 `key_model_access_denied`**. Fix via `POST /key/info` (GET, query param) then `POST /key/update` with `{"key":...,"models":["deepseek-v4-flash","gpt-5.5","gpt-5.4","gpt-5.4-mini","gpt-5.6","gpt-5.6-sol"]}` using the master key (pod env `$LITELLM_MASTER_KEY`; admin routes are `/key/*` NOT `/v1/key/*` in this build; `/v1/responses` + `/v1/chat/completions` both hit the 403 first). `/key/update` accepted `models` (did not need `/key/regenerate`).
2. **Routing:** `litellm_settings.aliases` is **INERT in litellm 1.96.2** — it never populates `litellm.model_alias_map`, so no rewrite happens. After the key-scope fix, `model: gpt-5.5` moved from 403 to **400 "Invalid model name passed in model=gpt-5.5"** (router has only `deepseek-v4-flash` in model_list). The WORKING mechanism is `router_settings.model_group_alias: {gpt-5.5: deepseek-v4-flash, ...}` (applied via `Router.update_settings`, `model_group_alias` is in `_allowed_settings`; resolved by `router._get_model_from_alias` in `_common_checks_available_deployment`). `kubernetes/development/litellm/config.yaml` now uses `model_group_alias` (NOT `litellm_settings.aliases`). After `kubectl apply -k kubernetes/development/litellm/` the Deployment does NOT auto-roll on a ConfigMap change (no configHash annotation) — must `kubectl -n development rollout restart deploy/litellm`.
3. **End-to-end verify** from the claudecodeui pod: `curl -s -o /dev/null -w '%{http_code}' -X POST http://litellm/v1/responses -H "Authorization: Bearer $LITELLM_API_KEY" ... -d '{"model":"gpt-5.5",...}'` → **200** (gpt-5.5/5.4/5.4-mini/5.6/5.6-sol all 200; deepseek-v4-flash stays 200).
