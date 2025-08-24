# VPN Apps

This directory contains manifests and configuration for VPN-related applications deployed in the la1r Kubernetes cluster.

## Structure
- **wg-easy/**: Contains the wg-easy WireGuard VPN server deployment, configuration, and ingress.
- **kustomization.yml**: Kustomize entrypoint for all VPN apps.
- **namespace.yml**: Namespace definition for grouping VPN resources.

## Usage
- Apply the manifests in this directory to deploy VPN services and their dependencies.
- For details on individual apps, see their respective subdirectories (e.g., `wg-easy/`).

## References
- [wg-easy Documentation](https://github.com/WeeJeWel/wg-easy)
