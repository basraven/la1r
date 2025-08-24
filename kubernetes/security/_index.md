# Security Apps

This directory contains manifests and configuration for security-related applications deployed in the la1r Kubernetes cluster.

## Structure
- **vaultwarden/**: Contains the Vaultwarden (Bitwarden-compatible) password manager deployment, including persistent storage, ingress, and middleware configuration.
- **kustomization.yaml**: Kustomize entrypoint for all security apps.
- **namespace.yml**: Namespace definition for grouping security resources.

## Usage
- Apply the manifests in this directory to deploy security services and their dependencies.
- For details on individual apps, see their respective subdirectories (e.g., `vaultwarden/`).

## References
- [Vaultwarden Documentation](https://github.com/dani-garcia/vaultwarden)
