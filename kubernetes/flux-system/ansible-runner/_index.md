# Flux CD Ansible Runner

This directory contains the Flux CD components responsible for automatically triggering an Ansible playbook run when changes are detected in the Ansible configuration within the `la1r` Git repository.

## Overview
This system uses Flux to monitor specific paths in the Git repository. When a change is detected, a Flux Kustomization triggers a Kubernetes Job. This Job runs an Ansible container that clones the latest configuration, decrypts credentials, and executes the main Ansible playbook (`site.yml`).

## Workflow
1.  **GitRepository Source (`gotk-sync-ansible.yml`)**: A Flux `GitRepository` resource named `ansible-only` is defined to monitor the `rick` branch of the `la1r` repository. It is configured to only pay attention to changes within the `/cicd/ansible/` and `/kubernetes/flux-system/ansible-runner/job` directories.

2.  **Kustomization Trigger (`gotk-sync-ansible.yml`)**: A Flux `Kustomization` resource named `ansible-job` points to the `ansible-only` source. It watches the `./kubernetes/flux-system/ansible-runner/job` path. When Flux detects a change in this path (which happens on every commit to the monitored paths), it applies the manifests within, effectively launching the Ansible runner Job.

3.  **Ansible Runner Job (`job/ansible-runner.yml`)**: This is the core component that executes the Ansible playbook.
    - **Container**: Uses the `quay.io/ansible/ansible-runner:latest` image.
    - **Execution Steps**:
        1.  Imports GPG keys from the `gpg-automated-keys` secret.
        2.  Clones the main `la1r` repository.
        3.  Clones the private `la1r-cred` repository using a GitHub PAT from the `github-la1r-cred-pat` secret.
        4.  Executes the `decrypt.sh` script within the credentials repository.
        5.  Navigates to `/la1r/cicd/ansible-new` and runs the `ansible-playbook` command against the `site.yml` playbook.
    - **Secrets & Volumes**:
        - Mounts the `gpg-automated-keys` secret to import GPG keys.
        - Mounts the host's `id_rsa` key for SSH access if needed by Ansible.
        - Uses a GitHub PAT for cloning the private credentials repo.
    - **Lifecycle**: The Job is configured to be deleted 60 seconds after completion (`ttlSecondsAfterFinished: 60`).

### Supporting Components
- **GPG Key Import (`import-gpg-keys.sh`)**: A helper script to create the `gpg-automated-keys` secret from local GPG key files. This is a manual, one-time setup step.
- **Namespace (`namespace.yml`)**: Defines the `ansible` namespace where the runner Job is executed.

## Directory Structure
- `gotk-sync-ansible.yml`: Defines the Flux `GitRepository` and `Kustomization` resources.
- `job/ansible-runner.yml`: The Kubernetes Job manifest that runs the Ansible playbook.
- `import-gpg-keys.sh`: Script for manually creating the required GPG secret.
- `kustomization.yml`: The Kustomize entrypoint for this component.

## References
- [Flux CD Documentation](https://fluxcd.io/)
- [Ansible Runner Documentation](https://ansible-runner.readthedocs.io/en/latest/)
