# Flux CD Webhook Receiver & Local Git Hook

This directory contains components that enable immediate, push-button reconciliation of Flux from a local development environment.

## Overview
While Flux automatically synchronizes with the Git repository at a set interval (e.g., every 2 minutes), this can slow down rapid development and testing. This system provides a mechanism to trigger a Flux reconciliation instantly after a `git push` command is executed locally.

**Note:** This component is currently disabled in the main `flux-system/kustomization.yaml`.

## Workflow
1.  **Local Git Hook Setup (`configure-local-githook.sh`)**: A developer runs this script once on their local machine. It creates a `post-push` hook in their local `.git/hooks` directory.

2.  **Git Push**: The developer makes changes and runs `git push` as usual.

3.  **Hook Execution**: After the push completes successfully, the `post-push` hook automatically executes the `trigger-flux.sh` script.

4.  **Flux Reconciliation Trigger (`trigger-flux.sh`)**: This script uses `kubectl annotate` to set the `reconcile.fluxcd.io/requestedAt` annotation on the `flux-system` Flux `Receiver` resource. This annotation is a signal that tells Flux's notification-controller to immediately reconcile the associated resource.

5.  **Flux Receiver (`webhook-receiver.yml`)**: The `Receiver` is configured to listen for this trigger and, in response, reconcile the main `flux-system` `GitRepository` source. This pulls the latest changes from Git into the cluster without waiting for the next scheduled run.

## Key Components
- **`webhook-receiver.yml`**: Defines the Flux `Receiver` resource that listens for the reconciliation trigger.
- **`trigger-flux.sh`**: The script that performs the `kubectl annotate` command to trigger the receiver.
- **`configure-local-githook.sh`**: A one-time setup script to install the `post-push` hook on a developer's machine.

This setup provides a significant quality-of-life improvement for developers by creating a tight feedback loop between committing code and seeing it live in the cluster.

## References
- [Flux Webhook Receivers](https://fluxcd.io/flux/components/notification/receivers/#triggering-a-reconcile)
