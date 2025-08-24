# Media Apps

This directory contains manifests and configuration for media-related applications deployed in the la1r Kubernetes cluster.

## Structure
- **immich/**: Contains the Immich self-hosted photo and video backup solution, including app, database, persistent storage, and ingress configuration.
- **kustomization.yml**: Kustomize entrypoint for all media apps.
- **namespace.yml**: Namespace definition for grouping media resources.
- **postgres-config.yaml**: Configuration for the Immich PostgreSQL database.

## Usage
- Apply the manifests in this directory to deploy media services and their dependencies.
- For details on individual apps, see their respective subdirectories (e.g., `immich/README.md`).

## References
- [Immich Documentation](https://immich.app/docs/)
