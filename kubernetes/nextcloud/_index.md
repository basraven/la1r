# Nextcloud Stack

This directory contains manifests and configuration for deploying Nextcloud and its supporting services in the la1r Kubernetes cluster.

## Structure
- **nextcloud/**: Main Nextcloud application deployment and configuration.
- **mariadb/**: MariaDB database deployment for Nextcloud.
- **redis/**: Redis instance for Nextcloud caching and session storage.
- **email/**: Email relay or SMTP configuration for Nextcloud notifications.
- **middleware.yml**: Traefik middleware for authentication and session management.
- **kustomization.yaml**: Kustomize entrypoint for all Nextcloud-related resources.
- **namespace.yml**: Namespace definition for grouping Nextcloud resources.

## Usage
- Apply the manifests in this directory to deploy Nextcloud and all required dependencies.
- For details on each component, see their respective subdirectories (e.g., `nextcloud/`, `mariadb/`, `redis/`, `email/`).

## References
- [Nextcloud Documentation](https://docs.nextcloud.com/)
