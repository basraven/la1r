# Monica CRM Kubernetes Deployment (la1r)

This directory contains all manifests required to run Monica, a personal relationship management (CRM) tool, in the la1r Kubernetes cluster.

## Overview
Monica is deployed as a two-tier application consisting of the main Monica web application and a MariaDB database backend. It is exposed securely via Traefik Ingress and uses persistent storage for all application and database data.

## Key Components

### 1. Application Deployment (`monica.yml`)
- **Deployment**: Runs the `monica:apache` container, pinned to the `jay-c` node.
- **Configuration**: Configured via environment variables, which pull sensitive data (like `APP_KEY`, `DB_USERNAME`, `DB_PASSWORD`) from the `monica-db-credentials` Kubernetes secret.
- **Storage**: Mounts a PersistentVolumeClaim `monica-data-claim` to `/var/www/html/storage` for persistent application data.

### 2. Database Deployment (`monica-db.yml`)
- **Deployment**: Runs a `mariadb:11` container, also pinned to the `jay-c` node.
- **Configuration**: The database is named `monica`. It uses the `monica-db-credentials` secret for the database user and password.
- **Storage**: Mounts a PersistentVolumeClaim `monica-database-claim` to `/var/lib/mysql` for persistent database storage.

### 3. Networking
- **Services**: 
  - `monica`: A ClusterIP service for the main application.
  - `monica-db`: A ClusterIP service for the MariaDB database, allowing the application to connect to it.
- **Certificate**: A `cert-manager` Certificate resource is defined to automatically issue a TLS certificate for `monica.bas` and `www.monica.bas` from the `la1r` ClusterIssuer.
- **Ingress**: An Ingress resource exposes the Monica application at `https://monica.bas`. It enforces HTTPS and uses the Sablier middleware for access control.

### 4. Security (`middleware.yml`)
- **Sablier Middleware**: The Ingress is protected by the `sablier-monica` Traefik middleware. This provides a dynamic authentication layer, requiring users to authenticate through Sablier before accessing the Monica application.
- **Secrets**: All sensitive credentials are managed via the `monica-db-credentials` secret, which must be created separately.

### 5. Persistent Storage (`pv/`)
- **PersistentVolumes**: Two `hostPath` PersistentVolumes are defined, pointing to `/mnt/ssd/na/monica/data` and `/mnt/ssd/na/monica/database`.
- **PersistentVolumeClaims**: Two corresponding PVCs (`monica-data-claim` and `monica-database-claim`) are created to claim this storage for the application and database pods.

## Directory Structure
- `monica.yml`: Main Monica application deployment, service, certificate, and ingress.
- `monica-db.yml`: MariaDB database deployment and service.
- `middleware.yml`: Traefik middleware for Sablier authentication.
- `pv/`: Contains `monica-pv.yml` and `monica-pvc.yml` for storage definitions.
- `kustomization.yml`: Kustomize entrypoint for the Monica application.

## References
- [Monica Official Site](https://www.monicahq.com/)
