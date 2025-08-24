# Flux CD SOPS GPG Secret Management

This directory contains the Flux CD configuration for managing encrypted Kubernetes secrets using Mozilla SOPS with GPG.

## Overview
This system provides a secure, GitOps-native way to manage sensitive information like API keys, passwords, and certificates. Secrets are encrypted and stored in a dedicated private Git repository (`la1r-cred`). Flux is configured to automatically fetch, decrypt, and apply these secrets to the cluster.

## Workflow
1.  **Secret Storage**: All sensitive values are encrypted using SOPS and a GPG key, then committed to the `la1r-cred` private Git repository.

2.  **GitRepository Source**: The `flux-sops-gpg.yaml` manifest defines a Flux `GitRepository` resource that points to the `la1r-cred` repository. Flux uses an SSH key (stored in the `flux-pgp-secret` Kubernetes secret) to clone this private repo.

3.  **Decryption Setup**: The manifest also defines a Flux `Kustomization` resource. This resource is configured with a `decryption` block specifying `sops` as the provider.

4.  **GPG Key**: The decryption process relies on a GPG private key, which must be stored in a Kubernetes secret named `sops-gpg` within the `flux-system` namespace. Flux's Kustomize controller uses this key to decrypt any SOPS-encrypted files it finds in the source repository.

5.  **Synchronization**: Flux periodically pulls the `la1r-cred` repository, decrypts the secrets in-memory, and applies them to the cluster, ensuring the cluster's secrets are always in sync with the encrypted versions in Git.

## Key Components
- **`flux-sops-gpg.yaml`**: The core manifest defining the `GitRepository` source for secrets and the `Kustomization` that enables SOPS decryption.
- **`sops-gpg` Secret**: A Kubernetes secret (not defined here) that must contain the GPG private key used for decryption. This is a prerequisite for the system to work.
- **`la1r-cred` Git Repository**: A separate, private repository where the SOPS-encrypted secrets are stored.

## References
- [Flux CD SOPS Guide](https://fluxcd.io/flux/guides/sops/)
- [Mozilla SOPS Documentation](https://github.com/mozilla/sops)
