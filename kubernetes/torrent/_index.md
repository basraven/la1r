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

## References
- [Jackett](https://github.com/Jackett/Jackett)
- [Jellyfin](https://jellyfin.org/docs/)
- [Jellyseerr](https://docs.jellyseerr.com/)
- [qBittorrent](https://github.com/qbittorrent/qBittorrent)
- [Radarr](https://radarr.video/docs/)
- [Sonarr](https://sonarr.tv/)
