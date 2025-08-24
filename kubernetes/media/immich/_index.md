# Immich

This directory contains configuration and manifests for deploying Immich, a self-hosted photo and video backup solution, in the la1r Kubernetes cluster.

## Overview
Immich provides a private, cloud-based photo and video management platform with mobile and web clients. It is deployed with persistent storage and can integrate with existing database secrets for secure operation.

## Key Components
- **Deployment/Service YAMLs**: Kubernetes manifests to deploy Immich and its supporting services.
- **Persistent Volumes**: Storage for photos, videos, and metadata.
- **Secrets**: Database credentials and other sensitive configuration (see below).

## Usage
- Deploy the manifests in this directory to run Immich in the `media` namespace.
- After installation, deploy `../../../credentials/kubernetes/nextcloud-dbsecret.yaml` in the `media` namespace (not in `nextcloud`) to provide the required database secret.
- Access Immich via the configured ingress or service endpoint.

## References
- [Immich Documentation](https://immich.app/docs/)