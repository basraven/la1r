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

## Blocking executable / malware downloads (Sonarr / Radarr)

Indexers (notably 1337x) carry fake pre-release "video" torrents that are really a
single executable — e.g. `MobLand S02E05 1080p HD h264 ETHEL.exe` or
`South Park S29E03 1080p WEB H264-MeGusta.exe`. Without protection Sonarr/Radarr grab
them, qBittorrent downloads the `.exe`, Sonarr warns "No files found are eligible for
import", and the same release is re-grabbed week after week.

The fix is the built-in per-indexer **Advanced → Fail Downloads** option (Sonarr v4 /
Radarr v6). Two built-in lists (not editable):

| Option | Extensions |
| --- | --- |
| Executables | `.bat`, `.cmd`, `.exe`, `.sh` |
| Potentially Dangerous | `.arj`, `.lnk`, `.lzh`, `.ps1`, `.scr`, `.vbs`, `.zipx` |

With it enabled, once the download completes Sonarr/Radarr reject the file
(`ImportRejectionReason.ExecutableFile`/`DangerousFile`), mark the download **failed**,
remove it from qBittorrent, and **blocklist the release** — so it is never grabbed
again. The decision is made by Sonarr/Radarr; qBittorrent just obeys.

This lives in the app DB on the PVC (like `trustedNetworks` above), not in any manifest,
so a wiped DB or a newly added indexer loses it. Re-apply with:

```bash
KUBECONFIG=~/.kube-la1r/config ./scripts/enable-fail-downloads.sh
```

The script sets `failDownloads=[0,1]` on every indexer in both apps (via the API with
`?forceSave=true`, which skips the connection test that Jackett 400s on). It is
idempotent. Equivalent UI path: Settings → Indexers → each indexer → Advanced →
Fail Downloads → check Executables + Potentially Dangerous.

Verify: `GET /api/v3/blocklist` shows the fake releases, and re-searching logs
`BlocklistSpecification|... is blocklisted, rejecting`.

> Caveat: on Sonarr v4 / Radarr v6 this check runs at import-time, so the `.exe` briefly
> lands in `/torrent` before being removed and blocklisted. The true pre-download
> rejection (`RejectTorrentFilesWithBlockedExtensionsWhileGrabbing`, which parses the
> `.torrent` file list at grab time) only exists in Sonarr v5.

## References
- [Jackett](https://github.com/Jackett/Jackett)
- [Jellyfin](https://jellyfin.org/docs/)
- [Jellyseerr](https://docs.jellyseerr.com/)
- [qBittorrent](https://github.com/qbittorrent/qBittorrent)
- [Radarr](https://radarr.video/docs/)
- [Sonarr](https://sonarr.tv/)
