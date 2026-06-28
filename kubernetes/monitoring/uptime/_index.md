# Uptime Monitoring (Gatus)

Service availability monitoring for the la1r homelab. Tracks both internal (ClusterIP) and public-facing (ingress) endpoints, with awareness of Sablier-scaled services.

## Architecture

```
Gatus Pod (monitoring ns, jay-c)
├── gatus container (ghcr.io/twin/gatus:v5.15.0)
│   ├── Probes cluster-internal services (http://service.namespace:port)
│   ├── Probes public endpoints (https://auth.la1r.com, https://toggle.la1r.com)
│   ├── Checks SSL certificate expiry (< 30 days → alert)
│   ├── Sends alerts → ntfy (topic: uptime)
│   ├── Exposes /metrics → Prometheus → Alertmanager → Discord
│   └── Dashboard at https://status.bas
│
└── sablier-proxy sidecar (alpine, Go binary)
    ├── /health?deployment=X&namespace=Y&check-url=Z
    ├── Service reachable → 200 (healthy)
    ├── Service unreachable + deployment has replicas=0 + no crash conditions
    │     → 200 (intentionally sleeping: sablier-sleeping or manually-disabled)
    └── Service unreachable + deployment has crash conditions
          → 503 (real outage)
```

## Endpoint Groups

Endpoints are organized by Kubernetes namespace for intuitive navigation:

| Group | Namespace | Type |
|---|---|---|
| `public` | — | Internet-facing (auth.la1r.com, toggle.la1r.com) |
| `nodes` | — | Physical hosts (ICMP/TCP) |
| `monitoring` | monitoring | Prometheus, Grafana-MCP, Alertmanager, ntfy, etc. |
| `security` | security | Authentik, Vaultwarden |
| `torrent` | torrent | Jackett, qBittorrent, Radarr, Sonarr, Jellyfin*, Jellyseerr* |
| `ai` | ai | mcp-kubernetes, Langflow*, Ollama*, etc. |
| `development` | development | ClaudeCodeUI, OpenVSCode Server, Ubuntu XFCE4* |
| `dns` | dns | Pi-hole |
| `headlamp` | headlamp | Headlamp |
| `registry` | registry | Container registry |
| `storage` | storage | MinIO |
| `vpn` | vpn | WireGuard Easy |
| `workflows` | workflows | Argo Workflows |
| `online` | online | Public Traefik, ddclient, Service Toggle |
| `crm` | crm | Monica* |
| `nextcloud` | nextcloud | Nextcloud* |
| `media` | media | Immich* |
| `gaming` | gaming | Enshrouded* |
| `traefik` | traefik | Internal Traefik, Sablier |
| `cert-manager` | cert-manager | Certificate management webhook |

\* Sablier-managed — scales to 0 when idle. Probed via sablier-proxy; alerts only fire if genuinely broken, not when sleeping.

## Files

| File | Purpose |
|---|---|
| `gatus.yml` | Deployment (2 containers), Service, Certificate, Ingress, RBAC |
| `kustomization.yml` | Kustomize entry point with ConfigMap generators |
| `config/config.yaml` | Gatus endpoint configuration (~65 endpoints, 20 groups) |
| `sablier-proxy/main.go` | Go source for the Sablier-aware health proxy sidecar |

## Deployment

```bash
kubectl apply -k kubernetes/monitoring/uptime/
```

Or as part of the full monitoring stack:

```bash
kubectl apply -k kubernetes/monitoring/
```

## Access

- **Dashboard**: [https://status.bas](https://status.bas)
- **Metrics**: Prometheus scrapes `gatus:8080/metrics` (job: `gatus`)
- **Alerts**: Routed through Alertmanager → Discord for critical issues

## Alert Rules

| Alert | Expression | Severity |
|---|---|---|
| `ServiceUnreachable` | `gatus_result{success="false"} == 1` for 2m | critical |
| `HighResponseTime` | `gatus_result_time > 2000` for 5m | warning |
| `CertificateExpiringSoon` | `gatus_certificate_expiry_days < 30` | warning |

## Sablier Integration

The `sablier-proxy` sidecar prevents false alerts when Sablier intentionally scales deployments to 0. It queries the Kubernetes API to check if a deployment has the `sablier.enable: "true"` label and `spec.replicas == 0`. The proxy is compiled from Go source via an init container at pod startup.

## Resource Usage

| Container | CPU Req/Lim | Memory Req/Lim |
|---|---|---|
| gatus | 25m / 100m | 32Mi / 128Mi |
| sablier-proxy | 10m / 50m | 16Mi / 64Mi |
| sablier-proxy-build (init) | 100m / 500m | 256Mi / 512Mi |

## References

- [Gatus Documentation](https://github.com/TwiN/gatus)
- [Gatus v5 Configuration](https://github.com/TwiN/gatus?tab=readme-ov-file#configuration)
