# Prometheus

Monitoring stack (Prometheus + alertmanager + blackbox + pushgateway + gatus +
kubewatch + node-exporter) for the homelab.

## Config layout
- `config/prometheus-config.yml` — generated into the `prometheus-config`
  ConfigMap (with a content-hash suffix) and mounted at
  `/etc/prometheus/prometheus.yml`.
- `config/rules.yml` → `prometheus-rules` ConfigMap (alerts/recording rules).
- `config/targets.json` → `prometheus-targets` ConfigMap (file_sd; currently
  disabled — target host decommissioned).
- `prometheus-rbac.yml` — RBAC for pod/service discovery **and** for scraping
  MetalLB metrics (see below).
- Because the ConfigMaps are generated with a hash suffix, editing a config
  file and reapplying the kustomization triggers a Prometheus rollout (clean
  reload, no manual `--web.config` dance).

## Scrape jobs of note
- `node-exporter` — pods annotated `prometheus.io/scrape=true` over HTTP
  (cert-manager, node-exporter, …). MetalLB is excluded from this job.
- `metallb` — MetalLB v0.16 metrics are **HTTPS-only** (self-signed) on :9120
  with native RBAC, so this job uses `scheme: https`,
  `insecure_skip_verify: true` and a bearer token. Two pieces make it work:
  - `prometheus-metallb-metrics` ClusterRole/Binding granting `get` on the
    non-resource URL `/metrics` to the `prometheus` ServiceAccount;
  - the MetalLB controller/speaker RBAC to create
    `tokenreviews`/`subjectaccessreviews` (patched in
    `kubernetes/metallb-system/kustomization.yml`).
  See `kubernetes/metallb-system/_index.md`.
- `traefik_metrics` — the two Traefik instances (`seb_scrape` annotation, :8082).
- `gatus`, `blackbox`, `pushgateway`, `pb`, `targetsjson` (disabled).

## Access
- UI: `https://prometheus.bas` (LAN, behind Traefik).
- Alerts: `https://alerts.bas` (alertmanager).
- Gatus (status): `https://status.bas`.

## Apply
```
kubectl apply -k kubernetes/monitoring/prometheus/
```

## Checks
- `kubectl exec deploy/prometheus -n monitoring -c prometheus -- wget -qO- \
  http://127.0.0.1:9090/api/v1/targets` — no DOWN targets.