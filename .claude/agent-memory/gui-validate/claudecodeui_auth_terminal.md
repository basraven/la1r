---
name: claudecodeui-auth-terminal
description: CloudCLI UI (claude.bas) auth wall + terminal architecture — single-user login, no default creds, xterm.js web-terminal panel, codex installed in container
metadata:
  type: reference
---

# CloudCLI UI (https://claude.bas) — auth wall and terminal

Validated 2026-08-22. The `claudecodeui` Deployment (`namespace development`, port 3001, image `claudecodeui:v5`, upstream [siteboon/claudecodeui](https://github.com/siteboon/claudecodeui), npm `@cloudcli-ai/cloudcli`) serves a **login wall** before any UI is reachable.

## Auth model (blocks browser validation)
- `/api/auth/status` returns `{"needsSetup":false,"isAuthenticated":false}` → a user **already exists** and I have **no credentials**.
- CloudCLI is **single-user**: the first registered user is the admin; when a user exists, registration/setup is closed (login page shows "Welcome Back", no signup link).
- No default username/password exists (bcrypt-hashed; DB under `DATABASE_PATH=/home/basraven/.claudecodeui` on the `openvscode-server-home` hostPath PVC at `/mnt/ssd/ha/openvscode-server/home` on the cluster node — NOT readable from this host).
- No saved session: `playwright-mcp/storage-state.json` is `{}`.
- Logged-out console noise is expected: `GET /api/plugins` → 401, `GET /api/taskmaster/installation-status` → 401, warning "No authentication token found for WebSocket connection". Not real errors.

## Terminal (what the user would run codex in)
- UI is a custom IDE-like web app (chat interface + file explorer + Git + sessions), **not** VS Code code-server. It uses **xterm.js** (`P9.Terminal`, FitAddon/WebLinksAddon/WebglAddon/ClipboardAddon) with a **WebSocket shell** (`connectToShell`, wsRef) — see `index-Bz9vXV2m.js`.
- Terminal is provided by a plugin: `{id:"web-terminal", translationKey:"terminalPlugin", ...}`; toggled via a **square-terminal** (lucide) icon button in the UI; there is a "Terminal Shortcuts" panel (Esc/Tab/Shift+Tab/Arrow keys, paste, scroll down). Exact Ctrl+`-style toggle shortcut was not confirmable because login blocks the shell UI.
- Terminal is project/session-aware (`selectedProject`, `selectedSession`, `initialCommand`, `minimal`/`isPlainShell` variants).
- **codex is reachable from the terminal**: `@openai/codex` is installed globally in the image (Dockerfile), and init.sh writes/merges `~/.codex/config.toml` pointing codex at LiteLLM (`model_provider="litellm"`, base `http://litellm/v1`, `wire_api="responses"`, model `deepseek-v4-flash`). See [[claudecodeui_codex_config]] (k8s-engineer memory) for routing details.

## Practical notes for future GUI validation
- To validate past the login wall you need the admin username/password (only basraven knows it) OR a reset of the auth DB on the node path.
- Traefik serves the app at `claude.bas` (HTTP 200); the raw pod IP is NOT reachable from this host.
