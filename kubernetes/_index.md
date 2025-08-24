# la1r Kubernetes Cluster Root

## Overview
This directory contains the root manifests, scripts, and instructions for initializing and managing the la1r Kubernetes cluster. It serves as the entry point for cluster bootstrapping, network setup, and core infrastructure deployment.

## Structure
- **calico/**: Networking (CNI) configuration and manifests
- **cert-manager/**: TLS certificate management
- **cluster/**: Core cluster configuration (kubeadm, RBAC, etc.)
- **dns/**: DNS and Pi-hole deployment
- **flux-system/**: GitOps and automation via Flux
- **media/**, **monitoring/**, **torrent/**, **workflows/**, etc.: Application and infrastructure stacks
- **storage/**: Persistent storage setup
- **Other subdirectories**: Specialized apps and system components

## Usage
1. Initialize the cluster using Ansible:
   ```bash
   (cd /cicd/ansible && ./kubernetes_init && ./kubernetes_fetch)
   ```
2. Untaint the control plane node to allow scheduling:
   ```bash
   kubectl taint nodes --all node-role.kubernetes.io/control-plane-
   ```
3. Apply Calico networking:
   ```bash
   kubectl apply -k kubernetes/calico
   ```
4. Join additional nodes using the token from the main node:
   ```bash
   kubeadm token create --print-join-command
   # Run the output on secondary nodes
   ```
5. Install Flux and deploy GitOps automation:
   ```bash
   cd kubernetes/flux && ./deploy.sh
   ```
6. Apply storage node labels:
   ```bash
   kubernetes/storage/node-labels/node-labels.sh
   ```

## References
- [Kubernetes Documentation](https://kubernetes.io/docs/)