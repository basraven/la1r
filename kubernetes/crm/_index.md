# CRM Apps

This directory contains manifests and configuration for CRM (Customer Relationship Management) applications deployed in the la1r Kubernetes cluster.

## Structure
- **monica/**: Contains the Monica personal CRM deployment, including app and database manifests, persistent storage, middleware, and ingress configuration.
- **kustomization.yaml**: Kustomize entrypoint for all CRM apps.
- **namespace.yml**: Namespace definition for grouping CRM resources.

## Usage
- Apply the manifests in this directory to deploy CRM applications and their dependencies.
- For details on individual apps, see their respective subdirectories (e.g., `monica/README.md`).

## References
- [Monica CRM](https://www.monicahq.com/)
