# Storage Apps

This directory contains manifests and configuration for storage-related applications and provisioners in the la1r Kubernetes cluster.

## Structure
- **local-path-provisioner/**: Contains the local-path-provisioner deployment for dynamic local PV provisioning.
- **minio/**: MinIO object storage deployment and configuration.
- **kustomization.yaml**: Kustomize entrypoint for all storage apps.
- **namespace-local-path-storage.yml**: Namespace for local-path-provisioner resources.
- **namespace-storage.yml**: Namespace for storage apps.

## Usage
- Apply the manifests in this directory to deploy storage provisioners and services.
- For details on each component, see their respective subdirectories (e.g., `local-path-provisioner/`, `minio/`).

## References
- [Local Path Provisioner](https://github.com/rancher/local-path-provisioner)
- [MinIO Documentation](https://min.io/docs/)
