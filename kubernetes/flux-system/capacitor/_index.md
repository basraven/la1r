# Capacitor (Gimlet) Release Manager

This directory contains the manifests for deploying Capacitor, a Kubernetes release manager from Gimlet, into the `flux-system` namespace.

## Overview
Capacitor provides a UI and a set of controllers to help developers understand the state of their applications in Kubernetes. It visualizes the GitOps sync process, shows deployment status, and provides a dashboard for releases. This deployment is managed via Flux, pulling the official Capacitor manifests from an OCI (Open Container Initiative) registry.

## Key Components

### 1. Flux CD Integration (`capacitor.yaml`)
- **OCIRepository**: A Flux `OCIRepository` resource is configured to pull the official Capacitor manifests from `oci://ghcr.io/gimlet-io/capacitor-manifests`.
- **Kustomization**: A Flux `Kustomization` resource applies the manifests from the OCI repository to the `flux-system` namespace, ensuring Capacitor is kept up-to-date automatically.

### 2. Networking (`capacitor-ingress.yaml`)
- **Ingress**: An Ingress resource exposes the Capacitor dashboard at `https://capacitor.bas`.
- **Certificate**: A `cert-manager` Certificate is used to automatically provision and renew a TLS certificate for `capacitor.bas` from the `la1r` ClusterIssuer.
- **NetworkPolicy**: A `NetworkPolicy` is in place to allow ingress traffic from all namespaces to the Capacitor pods, enabling other services in the cluster to communicate with it.

### 3. Security (`middleware.yml`)
- **Sablier Middleware (Optional)**: A Traefik `Middleware` for Sablier is defined but currently disabled in the `kustomization.yaml`. When enabled, it provides a dynamic, time-based authentication layer for accessing the Capacitor dashboard.
- The `deploy-add-sablier.yaml` patch, also disabled, is used to add the necessary labels to the Capacitor deployment to activate Sablier's proxying.

## Directory Structure
- `capacitor.yaml`: Defines the Flux resources for pulling and deploying Capacitor from its OCI registry.
- `capacitor-ingress.yaml`: Contains the Ingress, Certificate, and NetworkPolicy for exposing Capacitor securely.
- `middleware.yml`: Defines the optional Sablier authentication middleware.
- `deploy-add-sablier.yaml`: A Kustomize patch to enable Sablier integration (currently disabled).
- `kustomization.yaml`: The Kustomize entrypoint for this application.

## References
- [Gimlet Capacitor Documentation](https://gimlet.io/docs/capacitor-what-is-it)
- [Flux CD Documentation](https://fluxcd.io/)
