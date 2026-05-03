# Pod Priority Overview

PriorityClasses used in this cluster to prevent eviction under node pressure. Listed from highest to lowest priority.

| PriorityClass | Value | Preemption | Used by |
|---|---|---|---|
| `system-node-critical` | 2000001000 | PreemptLowerPriority | GPU workloads (`kubernetes/gpu/gpu.yml`) |
| `system-cluster-critical` | 2000000000 | PreemptLowerPriority | Flux system components (`flux-system/gotk-components.yaml`) |
| `dns-priority` | 500000000 | PreemptLowerPriority | DNS — Pi-hole, external-dns (`kubernetes/dns/`) |
| `security-priority` | 500000000 | PreemptLowerPriority | Security — vaultwarden, authentik (`kubernetes/security/`) |
| `traefik-priority` | 500000000 | PreemptLowerPriority | Ingress — Traefik, Sablier (`kubernetes/traefik/`) |
| `homeautomation-priority` | 100000000 | PreemptLowerPriority | Home automation (`kubernetes/homeautomation/`) |
| `development-priority` | 50000000 | PreemptLowerPriority | Development — openvscode-server, claudecodeui (`kubernetes/development/`) |
| `gaming-priority` | 50000000 | PreemptLowerPriority | Gaming — enshrouded (`kubernetes/gaming/`) |
| `torrent-priority` | 50000000 | PreemptLowerPriority | Torrent — qbittorrent, sonarr, radarr, jackett, jellyfin, jellyseerr, traefik-watcher (`kubernetes/torrent/`) |
| *(default)* | 0 | PreemptLowerPriority | Pods without explicit `priorityClassName` |

## Notes

- **`essential`** is referenced by `priorityClassName: essential` in the node-exporter DaemonSet (`kubernetes/monitoring/prometheus/exporters/node-exporter/prometheus-node-exporter.yml`) but no corresponding PriorityClass exists in the cluster. This means the node-exporter pods will fail to schedule if the PriorityClass isn't created.
