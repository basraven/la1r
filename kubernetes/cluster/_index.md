# Cluster Bootstrap & Core Configuration

This directory contains core manifests and configuration for bootstrapping and managing the la1r Kubernetes cluster.

## Overview
The resources here provide foundational cluster configuration, including kubeadm settings, RBAC for controllers, and other cluster-wide policies.

## Key Components
- **kubeadm-config.yaml**: Main kubeadm configuration for cluster initialization and upgrades.
- **kube-controller-manager-rbac.yml**: RBAC rules for the Kubernetes controller manager.
- **kustomization.yml**: Kustomize entrypoint for applying all resources in this directory.

## Usage
- Use these manifests when initializing a new cluster or making changes to core cluster configuration.
- Review and update kubeadm and RBAC settings as needed for upgrades or security changes.

## References
- [Kubernetes Cluster Bootstrapping](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)
