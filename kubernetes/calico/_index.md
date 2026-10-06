# Calico Networking

This directory contains the manifests and configuration for deploying Calico as the CNI (Container Network Interface) for the la1r Kubernetes cluster.

Current version: **Calico v3.32.2** (operator `quay.io/tigera/operator:v1.42.6`).

## Overview
Calico provides networking and network security for Kubernetes clusters. It enables high-performance, scalable networking using BGP and supports advanced network policy features.

## Key Components
- **tigera-operator.yaml**: The Tigera operator (RBAC + Deployment) that installs and manages the Calico CNI. Vendored from the upstream v3.32.2 release.
- **operator-crds.yaml**: The `operator.tigera.io` and `crd.projectcalico.org` CRDs, vendored from the upstream v3.32.2 release.
- **calico-installation.yaml**: The `Installation` custom resource describing the desired Calico networking configuration.
- **calico-bgp-config.yaml**: BGP configuration for peering and routing (not part of the kustomization; apply manually if used).
- **calicoctl.yaml**: Manifest for the Calico CLI tool for advanced management (not part of the kustomization; apply manually if used).

## Installing / Rebuilding
The CRDs in `operator-crds.yaml` are too large for client-side apply
(`installations.operator.tigera.io` is ~1.4MB, exceeding the 256KB
`last-applied-configuration` annotation limit), so they must be applied with
server-side apply *before* the operator and the `Installation` CR:

```bash
kubectl apply --server-side --force-conflicts -f operator-crds.yaml
kubectl apply -k kubernetes/calico/
```

## Upgrading
1. Download the operator and CRD manifests for the target Calico release and
   replace `tigera-operator.yaml` and `operator-crds.yaml` (keep the
   `# source:` header).
2. `kubectl apply --server-side --force-conflicts -f operator-crds.yaml`
3. `kubectl apply -k kubernetes/calico/` — the operator then rolls the CNI
   (`calico-node`, `calico-typha`, `calico-kube-controllers`) to the new version.

## Usage
- For advanced network policy or troubleshooting, use `calicoctl` as described in the official documentation.

## References
- [Calico Documentation](https://docs.tigera.io/)
- [Calico releases](https://github.com/projectcalico/calico/releases)
