# Development Tools

This directory contains manifests and configuration for development tools and environments deployed in the la1r Kubernetes cluster.

## Structure
- **openvscode-server/**: Contains the OpenVSCode Server deployment for browser-based development, including persistent storage, ingress, and security middleware.
- **kustomization.yml**: Kustomize entrypoint for all development tools.
- **namespace.yml**: Namespace definition for grouping development resources.

## Usage
- Apply the manifests in this directory to deploy development tools and their dependencies.
- For details on individual tools, see their respective subdirectories (e.g., `openvscode-server/README.md`).

## References
- [OpenVSCode Server](https://github.com/gitpod-io/openvscode-server)
