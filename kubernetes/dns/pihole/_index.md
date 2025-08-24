# Pi-hole Kubernetes Deployment (la1r)

This directory contains all manifests, configuration, and documentation for running Pi-hole as a DNS filtering solution in the la1r Kubernetes cluster.

## Overview
Pi-hole is deployed as a highly-available DNS resolver and ad-blocker for all clients in the cluster. It is exposed via Kubernetes Services and Ingress, with persistent storage, secure access, and automated DNS record management.

## Key Components

### 1. Deployment (`pihole.yml`)
- **Deployment**: Runs the official `pihole/pihole:2024.07.0` container on a specific node (`jay-c`).
- **ConfigMap**: Manages custom DNS entries and Pi-hole setup variables (e.g., upstream DNS, web theme, logging).
- **Environment**: Uses secrets for sensitive values (e.g., web admin password via `pihole-credentials`).
- **Probes**: Includes liveness/readiness probes for the web UI.
- **Volumes**: Supports persistent storage for `/etc/pihole` and `/etc/dnsmasq.d` (see `pv/`).

### 2. Services
- **ClusterIP Service**: Exposes Pi-hole internally on ports 80/443 (web) and 53 (DNS TCP/UDP).
- **LoadBalancer Service**: Exposes DNS on a fixed cluster IP (`192.168.6.91`) for LAN clients.

### 3. Certificate & Ingress
- **Certificate**: Uses cert-manager to generate TLS certs for `dns.bas` and `pihole.bas` via the `la1r` ClusterIssuer.
- **Ingress**: Exposes the Pi-hole web UI via Traefik, with HTTPS, custom middleware, and host rules for `dns.bas` and `pihole.bas`.

### 4. Middleware (`pihole-middleware.yml`)
- **Traefik Middleware**: Redirects root URL (`/`) to `/admin/` for the web UI.

### 5. External-DNS (`pihole-external-dns.yml`)
- **Deployment**: Runs `external-dns` with the Pi-hole provider to auto-populate DNS records based on K8s Services and Ingresses.
- **RBAC**: Grants access to required K8s resources.
- **Secrets**: Reads Pi-hole admin password from `pihole-credentials`.

### 6. Persistent Storage (`pv/`)
- **PersistentVolume & Claim**: Local storage for Pi-hole data and dnsmasq config, ensuring settings and logs persist across restarts.
- **Node Affinity**: Volumes are bound to the same node as the pod (`jay-c`).

## Usage
- **DNS**: Point clients to `192.168.6.91` for DNS, or use the internal ClusterIP for in-cluster services.
- **Web UI**: Access via `https://dns.bas/admin/` or `https://pihole.bas/admin/` (with valid credentials).
- **Management**: All config is managed via versioned manifests in this directory. Secrets should be created separately.

## Security
- **Web UI password**: Managed via Kubernetes Secret (`pihole-credentials`).
- **TLS**: All web access is HTTPS with valid certificates.
- **RBAC**: External-DNS is scoped to only what it needs.

## Directory Structure
- `pihole.yml` – Main deployment, services, configmap, ingress, certificate
- `pihole-middleware.yml` – Traefik middleware for UI redirect
- `pihole-external-dns.yml` – External-DNS deployment and RBAC
- `pv/` – PersistentVolume and PersistentVolumeClaim resources
- `kustomization.yml` – Kustomize entrypoint for this app

## References
- [Pi-hole documentation](https://docs.pi-hole.net/)
- [External-DNS docs](https://github.com/kubernetes-sigs/external-dns)
