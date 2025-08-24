# Workflows

This directory contains manifests and configuration for workflow automation tools deployed in the la1r Kubernetes cluster.

## Structure
- **argo/**: Contains the Argo Workflows deployment, configuration, and templates for running complex workflows and pipelines.
- **templates/**: Workflow templates and reusable components for Argo.
- **kustomization.yaml**: Kustomize entrypoint for all workflow-related resources.
- **namespace.yml**: Namespace definition for grouping workflow resources.

## Usage
- Apply the manifests in this directory to deploy workflow automation tools and their dependencies.
- For details on each component, see their respective subdirectories (e.g., `argo/`, `templates/`).

## References
- [Argo Workflows Documentation](https://argoproj.github.io/argo-workflows/)
