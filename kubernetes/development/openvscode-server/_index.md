# OpenVSCode Server Kubernetes Deployment (la1r)

This directory contains all manifests for running OpenVSCode Server, a web-based VS Code environment, in the la1r Kubernetes cluster.

## Overview
This deployment provides a persistent, personalized, and secure remote development environment accessible via a web browser. It is deployed with custom initialization, persistent storage for the user's home directory, and a multi-layered authentication system.

## Key Components

### 1. Deployment (`openvscode-server.yml`)
- **Image**: Uses `gitpod/openvscode-server:latest`.
- **Initialization**: A `ConfigMap` provides an `init.sh` script that runs on startup to:
  - Rename the default user to `basraven`.
  - Grant passwordless `sudo` privileges to the `basraven` user.
- **Execution**: The container starts as `root` to apply the initialization script, then switches to the `basraven` user to launch the VS Code server process.
- **Node Affinity**: The deployment is pinned to the `jay-c` node.

### 2. Storage (`pv/`)
- **PersistentVolume**: A `hostPath` PersistentVolume is defined, pointing to `/mnt/ssd/ha/openvscode-server/home2` on the host node.
- **PersistentVolumeClaim**: The `openvscode-server-home2-claim` PVC mounts the persistent volume into the container at `/home`, ensuring the user's home directory, settings, and extensions are preserved across restarts.

### 3. Networking
- **Service**: A ClusterIP service (`openvscode-server`) exposes the container's port `3000` on port `80` within the cluster.
- **Certificate**: A `cert-manager` Certificate is configured to automatically issue a TLS certificate for `code.bas`.
- **Ingress**: An Ingress resource makes the service accessible at `https://code.bas`, enforcing HTTPS.

### 4. Security (`middleware.yml`, `auth-middleware.yml`)
Access to the OpenVSCode Server is protected by a chain of two Traefik middlewares:
1.  **Sablier (`sablier-openvscode-server`)**: Provides a dynamic, time-based authentication layer. Users must first authenticate through Sablier to gain temporary access.
2.  **Basic Authentication (`auth-openvscode-server`)**: Adds a second layer of protection using Basic Auth. Credentials for this are stored in the `openvscode-server-middleware-basic-auth` Kubernetes secret.

This chained middleware approach ensures that access is both time-limited and requires a static secret, providing robust security.

## Directory Structure
- `openvscode-server.yml`: The main Deployment, Service, Certificate, and Ingress definitions.
- `middleware.yml`: Defines the Sablier authentication middleware.
- `auth-middleware.yml`: Defines the Basic Auth middleware.
- `pv/`: Contains `pv.yml` and `pvc.yml` for persistent storage.
- `kustomization.yml`: The Kustomize entrypoint for this application.

## References
- [OpenVSCode Server GitHub](https://github.com/gitpod-io/openvscode-server)
