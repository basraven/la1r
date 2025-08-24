# Calico Networking

This directory contains the manifests and configuration for deploying Calico as the CNI (Container Network Interface) for the la1r Kubernetes cluster.

## Overview
Calico provides networking and network security for Kubernetes clusters. It enables high-performance, scalable networking using BGP and supports advanced network policy features.

## Key Components
- **calico-installation.yaml**: Main Calico operator and custom resources for installation.
- **calico-bgp-config.yaml**: BGP configuration for peering and routing.
- **calicoctl.yaml**: Manifest for the Calico CLI tool for advanced management.

## Usage
- Apply the manifests in this directory to install and configure Calico networking and BGP peering in your cluster.
- For advanced network policy or troubleshooting, use `calicoctl` as described in the official documentation.

## References
- [Calico Documentation](https://docs.tigera.io/)
