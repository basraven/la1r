# MetalLB Installation Prerequisites

This document describes the required pre-installation steps for deploying MetalLB as a load balancer in the la1r Kubernetes cluster.

## Overview
MetalLB provides network load balancer functionality for bare-metal Kubernetes clusters. Before installing MetalLB, the cluster networking and node configuration must be updated for compatibility.

## Key Components
- **kube-proxy Configuration**: Ensure kube-proxy is set to IPVS mode with `strictARP` enabled.
- **Node Labeling**: Prepare nodes to be eligible for external load balancers.

## Usage
1. Edit the kube-proxy configmap:
   ```bash
   kubectl edit configmap -n kube-system kube-proxy
   ```
   Set the following in the config:
   ```yaml
   apiVersion: kubeproxy.config.k8s.io/v1alpha1
   kind: KubeProxyConfiguration
   mode: "ipvs"
   ipvs:
     strictARP: true
   ```
2. Label nodes to allow load balancer scheduling:
   ```bash
   kubectl label node linux-wayne node.kubernetes.io/exclude-from-external-load-balancers-
   # node/linux-wayne unlabeled
   ```

## References
- [MetalLB Installation Guide](https://metallb.universe.tf/installation/)