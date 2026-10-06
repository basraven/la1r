# system-audit

Streamlit app that audits the host (nmap/systemd checks) and reports via
`https://audit.bas` (behind authentik forward-auth).

## How it runs
- `config/app.py` + `config/requirements.txt` are bundled into the
  `system-audit-config` ConfigMap (`configMapGenerator` with
  `disableNameSuffixHash: true` — the ConfigMap name never changes).
- An **initContainer** creates a venv in an `emptyDir` and installs
  `config/requirements.txt`; the main container runs
  `/venv/bin/streamlit run ...`.
- The pod runs `privileged: true` with `hostPID` and hostPath mounts
  (`/var/log`, `/etc/systemd`, apt caches) to inspect the node.

## Python pins
- `streamlit` is pinned to `1.54.0` (was `1.33.0`). This resolves the three open
  Dependabot alerts: CVE-2026-10804 (low), CVE-2026-33682 (medium),
  CVE-2024-42474 (medium) — first fixed in 1.37.0/1.53.1/1.54.0.
- Other pins: `openai`, `pyyaml`, `kubernetes` (client libs).

## CRITICAL: after changing requirements.txt
Because the venv lives in an `emptyDir` and the ConfigMap name is stable,
editing `requirements.txt` does **not** trigger a pod restart by itself. Redeploy
and restart the Deployment:
```
kubectl apply -k kubernetes/monitoring/system-audit/
kubectl rollout restart deployment/system-audit -n monitoring
```

## Secrets
`ANTHROPIC_AUTH_TOKEN` (shown as env to the app) comes from the
`deepseek-apikey` Secret — referenced by name, never committed.

## Apply
```
kubectl apply -k kubernetes/monitoring/system-audit/
```