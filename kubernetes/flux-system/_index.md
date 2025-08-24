# Flux CD System (`flux-system`)

This directory contains all the core components, configurations, and extensions for the Flux CD GitOps engine that manages the `la1r` Kubernetes cluster.

## Overview
Flux CD is responsible for keeping the cluster state synchronized with the configuration defined in one or more Git repositories. It automates the deployment of applications and infrastructure, ensuring that the live state of the cluster matches the desired state in Git.

This setup is composed of several key parts:

### 1. Core Components (`gotk-components.yaml`)
This large manifest contains all the standard Kubernetes deployments for the GitOps Toolkit (GOTK) controllers, including:
- **Source Controller**: Manages Git, Helm, and OCI repository sources.
- **Kustomize Controller**: Runs Kustomize to apply manifests from the sources.
- **Helm Controller**: Manages Helm chart releases.
- **Notification Controller**: Handles inbound and outbound events.

These components form the backbone of the GitOps pipeline.

### 2. Main Repository Sync (`gotk-sync.yaml`)
This defines the primary synchronization loop for the `la1r` cluster itself.
- **GitRepository**: A `GitRepository` resource points to the `la1r` repository (`ssh://git@github.com/basraven/la1r`) on the `rick` branch.
- **Kustomization**: A `Kustomization` resource applies all manifests under the `/kubernetes` directory of the repository, effectively managing the entire cluster's application stack.

### 3. Ceryx Repository Sync (`gotk-sync-ceryx.yaml`)
This defines a separate, independent synchronization loop for the `ceryx` reverse proxy.
- **GitRepository**: Points to the `ceryx` repository (`ssh://git@github.com/basraven/ceryx`).
- **Kustomization**: Applies the manifests from the `/infra` directory within that repository.

### 4. Application Extensions
Subdirectories within `flux-system/` contain manifests for applications that extend or integrate with Flux:
- **`ansible-runner/`**: A system that triggers an Ansible playbook run via a Kubernetes Job whenever changes are pushed to the Ansible configuration in the Git repo. (See `ansible-runner/README.md` for details).
- **`capacitor/`**: The Gimlet Capacitor release manager, which provides a UI for observing the status of Flux-managed releases. (See `capacitor/README.md` for details).
- **`sops-gpg/`**: Configuration for Mozilla SOPS, used for decrypting secrets within the GitOps workflow.
- **`webhook-receiver/`**: A generic webhook receiver to trigger Flux reconciliations from external events (currently disabled).

## Directory Structure
- `gotk-components.yaml`: Core Flux CD controller deployments.
- `gotk-sync.yaml`: Main sync configuration for the `la1r` repo.
- `gotk-sync-ceryx.yaml`: Sync configuration for the external `ceryx` repo.
- `kustomization.yaml`: The top-level Kustomize resource that ties all components together.
- `ansible-runner/`: Sub-application for running Ansible playbooks.
- `capacitor/`: Sub-application for the Capacitor release manager UI.
- `sops-gpg/`: SOPS secret decryption configuration.
- `webhook-receiver/`: Inbound webhook handler.

## References
- [Flux CD Documentation](https://fluxcd.io/)

---

## Additional Details

### Sub-Applications

#### ansible-runner/
Runs Kubernetes Jobs to execute Ansible playbooks triggered by Flux Kustomizations. Used for cluster configuration tasks that require imperative automation.

#### capacitor/
Gimlet Capacitor release manager UI, deployed with ingress and optional authentication middleware. Allows for visual management of releases and deployments.

#### sops-gpg/
Holds the configuration for SOPS GPG key integration. Enables Flux to decrypt and apply encrypted Kubernetes secrets from Git.

#### webhook-receiver/
Contains manifests for a webhook receiver and scripts to trigger Flux reconciliation immediately after Git pushes, enabling faster feedback loops.

---

For more details on each component, see the respective subdirectory README files.
