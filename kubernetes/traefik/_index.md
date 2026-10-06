# Traefik Ingress Controller

This directory contains manifests and configuration for deploying the Traefik ingress controller and supporting middleware in the la1r Kubernetes cluster.

Current version: **Traefik v3.7.13** (CRDs API group `traefik.io/v1alpha1`).

## Overview
Traefik acts as the main ingress controller, routing external HTTP/HTTPS traffic to internal services. It supports middleware for authentication, rate limiting, and more.

There are **two independent Traefik instances** which must be kept isolated:

| Instance | Namespace | Entrypoint / VIP | Provider scope | IngressClass |
| --- | --- | --- | --- | --- |
| main | `traefik` | `192.168.6.2` | CRD `expose!=online` + Ingress (`ingressClass=lan`) across all namespaces | `lan` (default) |
| online | `online` | `192.168.6.129` | CRD `expose=online`, namespace `online` only | `online` |

The isolation is enforced by the CRD provider `labelSelector` (`expose!=online` vs `expose=online`), the provider `namespaces`/`allowCrossNamespace` settings, and separate ServiceAccounts/ClusterRoles (`traefik-ingress-controller` vs `online-traefik-ingress-controller`).

## Key Components
- **traefik.yml**: Main Traefik deployment and services.
- **traefik-crds.yml**: Traefik `traefik.io` CRDs plus the Gateway API CRDs.
- **traefik-rbac.yml**: RBAC for the main Traefik instance.
- **auth-middleware.yml**: Authentication middleware for the Traefik dashboard.
- **sablier/**: Sablier deployment used for scale-to-zero middleware.
- **kustomization.yml**: Kustomize entrypoint for all Traefik resources.
- **namespace.yml**: Namespace definition.

The `online` instance lives in `../online/traefik-online/`.

## Usage
- Apply the manifests in this directory to deploy Traefik and its middleware.
- Configure ingress resources in other apps to use Traefik as their ingress controller and reference middleware as needed.
- CRD-based middleware is referenced as `<namespace>-<name>@kubernetescrd` in Ingress annotations.

## Notes
- Traefik v3 requires `configmaps` and `nodes` read permissions in addition to the v2 set (see `traefik-rbac.yml`).
- The `traefik.containo.us` CRD API group was removed in v3 and no longer exists in this cluster.

## References
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Sablier Middleware](https://github.com/la1r/sablier)
