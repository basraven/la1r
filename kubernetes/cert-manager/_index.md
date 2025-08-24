# Cert-Manager

This directory contains manifests for deploying and configuring cert-manager in the la1r Kubernetes cluster.

## Overview
cert-manager automates the management and issuance of TLS certificates from various sources, including Let's Encrypt, for Kubernetes workloads. It is used to secure Ingress endpoints and internal services with automatically renewed certificates.

## Key Components
- **cert-manager.yml**: Installs the cert-manager CustomResourceDefinitions (CRDs), controller, and webhook components.
- **cluster-issuer-la1r.yml**: Defines a ClusterIssuer resource for issuing certificates (e.g., via Let's Encrypt or internal CA).
- **kustomization.yaml**: Kustomize entrypoint for cert-manager deployment.

## Usage
- Apply all manifests to install cert-manager and configure the cluster-wide issuer.
- Reference the ClusterIssuer in Certificate resources for Ingress and other services.

## References
- [cert-manager Documentation](https://cert-manager.io/docs/)
