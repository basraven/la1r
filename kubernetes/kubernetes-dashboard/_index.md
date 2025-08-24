# Kubernetes Dashboard

This directory contains manifests and configuration for deploying the Kubernetes Dashboard and supporting components in the la1r Kubernetes cluster.

## Overview
The Kubernetes Dashboard provides a web-based UI for managing and monitoring cluster resources. This setup includes RBAC, optional Helm-based installation, ingress, and authentication middleware.

## Key Components
- **kubernetes-dashboard-admin.yml**: Admin user and RBAC configuration for dashboard access.
- **kubernetes-dashboard-helm.yml**: Helm-based deployment manifest for the dashboard.
- **kubernetes-dashboard-ingress.yml**: Ingress resource for external access to the dashboard UI.
- **middleware.yml**: Traefik middleware for authentication and session management.
- **oauth2-proxy/**: Supporting manifests for OAuth2 authentication proxy integration.
- **kustomization.yaml**: Kustomize entrypoint for all dashboard resources.
- **namespace.yml**: Namespace definition for grouping dashboard resources.

## Usage
- Apply the manifests to deploy the dashboard and supporting authentication components.
- Access the dashboard via the configured ingress URL. Use the provided admin credentials or OAuth2 proxy for authentication.

## References
- [Kubernetes Dashboard Documentation](https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/)
