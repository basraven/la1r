# DNS Apps

This directory contains manifests and configuration for DNS-related applications deployed in the la1r Kubernetes cluster.

## Structure
- **pihole/**: Contains the Pi-hole DNS sinkhole deployment, including app, ingress, persistent storage, and middleware configuration.
- **kustomization.yml**: Kustomize entrypoint for all DNS apps.
- **namespace.yml**: Namespace definition for grouping DNS resources.

## Usage
- Apply the manifests in this directory to deploy DNS services and their dependencies.
- For details on individual apps, see their respective subdirectories (e.g., `pihole/README.md`).

## References
- [Pi-hole](https://pi-hole.net/)
