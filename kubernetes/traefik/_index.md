# Traefik Ingress Controller

This directory contains manifests and configuration for deploying the Traefik ingress controller and supporting middleware in the la1r Kubernetes cluster.

## Overview
Traefik acts as the main ingress controller, routing external HTTP/HTTPS traffic to internal services. It supports middleware for authentication, rate limiting, and more.

## Key Components
- **traefik.yml**: Main Traefik deployment and service.
- **traefik-crd1.yml**: CustomResourceDefinitions for Traefik.
- **traefik-rbac.yml**: RBAC configuration for Traefik.
- **auth-middleware.yml**: Middleware for authentication (e.g., basic auth).
- **sablier/**: Sablier authentication middleware deployment and configuration.
- **kustomization.yml**: Kustomize entrypoint for all Traefik resources.
- **namespace.yml**: Namespace definition for grouping Traefik resources.

## Usage
- Apply the manifests in this directory to deploy Traefik and its middleware.
- Configure ingress resources in other apps to use Traefik as their ingress controller and reference middleware as needed.

## References
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Sablier Middleware](https://github.com/la1r/sablier)
