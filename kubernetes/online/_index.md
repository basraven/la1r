# Online Services

This directory contains manifests and configuration for online services and dynamic DNS clients deployed in the la1r Kubernetes cluster.

## Structure
- **ddclient/**: Contains the ddclient deployment for dynamic DNS updates.
- **kustomization.yaml**: Kustomize entrypoint for all online services.
- **namespace.yml**: Namespace definition for grouping online service resources.

## Usage
- Apply the manifests in this directory to deploy online services and dynamic DNS clients.
- For details on each component, see their respective subdirectories (e.g., `ddclient/`).

## References
- [ddclient Documentation](https://ddclient.net/)
