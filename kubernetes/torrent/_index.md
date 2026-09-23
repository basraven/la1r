# Torrent Apps

This directory contains manifests and configuration for torrent and media download applications deployed in the la1r Kubernetes cluster.

## Structure
- **jackett/**: Jackett indexer deployment and configuration.
- **jellyfin/**: Jellyfin media server deployment and configuration.
- **jellyseerr/**: Jellyseerr request management app for Jellyfin.
- **qbittorrent/**: qBittorrent client deployment and configuration.
- **radarr/**: Radarr movie management and automation.
- **sonarr/**: Sonarr TV show management and automation.
- **kustomization.yaml**: Kustomize entrypoint for all torrent/media apps.
- **namespace.yml**: Namespace definition for grouping torrent/media resources.

## Usage
- Apply the manifests in this directory to deploy torrent/media services and their dependencies.
- For details on each component, see their respective subdirectories (e.g., `jackett/`, `jellyfin/`, `jellyseerr/`, `qbittorrent/`, `radarr/`, `sonarr/`).

## Reverse-proxy authentication (Sonarr / Radarr)

Sonarr and Radarr run with `AuthenticationRequired = DisabledForLocalAddresses`, meaning
"no password from the LAN, password from anywhere else". That only works if the app can
see the **real client IP**.

Traefik always adds `X-Forwarded-For`. If the app does not trust Traefik as a proxy it
logs `Unknown proxy: [::ffff:10.244.246.x]`, throws the header away, and classifies every
request as remote — so the LAN gets a password prompt / login page. Both apps also need
`allowedHosts` non-empty or their own API rejects a config save.

These settings live in `/config/config.xml` **on the PVC**, not in any manifest — the
deployment YAMLs only carry a comment pointing here. A wiped/recreated config volume
loses them.

| Setting | Value | Why |
| --- | --- | --- |
| `trustedNetworks` | `10.244.0.0/16` (pod CIDR) | trust Traefik's `X-Forwarded-For` |
| `allowedHosts` | `<app>.bas,www.<app>.bas,<app>,<app>.torrent,<app>.torrent.svc,<app>.torrent.svc.cluster.local` | host filter; short names are what Bazarr/Jellyseerr call in-cluster |

Both are applied only at startup — set them, then restart the Deployment.

```bash
# via the API (the app's own host filter blocks the svc name, so use the real hostname)
curl -sk -H 'Host: sonarr.bas' https://192.168.6.2/api/v3/config/host -H 'X-Api-Key: <key>'
# then PUT the same JSON back with the two fields set, and:
kubectl rollout restart deployment/sonarr -n torrent
```

Verify — LAN must pass, remote must still be challenged:

```bash
curl -s -o /dev/null -w '%{http_code}\n' -H 'X-Forwarded-For: 192.168.6.50' http://sonarr.torrent.svc.cluster.local/  # 200
curl -s -o /dev/null -w '%{http_code}\n' -H 'X-Forwarded-For: 8.8.8.8'      http://sonarr.torrent.svc.cluster.local/  # 401
```

## References
- [Jackett](https://github.com/Jackett/Jackett)
- [Jellyfin](https://jellyfin.org/docs/)
- [Jellyseerr](https://docs.jellyseerr.com/)
- [qBittorrent](https://github.com/qbittorrent/qBittorrent)
- [Radarr](https://radarr.video/docs/)
- [Sonarr](https://sonarr.tv/)
