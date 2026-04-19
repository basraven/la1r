# CLAUDE.md - la1r Repo Rules
Homelab infrastructure: K8s (manifests), Ansible (config), Terraform (cloud), Hugo (docs).

## Critical Restrictions
- **NEVER** run `git` commands (user handled).
- **K8s:** Never use `kubectl patch`; modify YAMLs directly. Write `logs` to files, don't stream to stdout.

## Core Scripts & Commands
- **K8s:** `kubectl apply -k kubernetes/<app>/`
- **Ansible:** `./ansible.sh`, `./ansible-dry-run.sh`. Use `--tags` or `--limit`.
- **Terraform:** `cd cloud/terraform/environments/<env>/<subenv>/ && ./apply.sh`
- **Docs:** `cd documentation/src/ && ./dev.sh`

## Kubernetes Standards
- **Structure:** `Deployment` -> `Service` -> `Certificate` -> `Ingress` in one `<app>.yml`.
- **PVs:** Located in `pv/` subfolder with separate `kustomization.yaml`.
- **Ingress:** Use `apiVersion: networking.k8s.io/v1`. TLS secret must match `Certificate`.

## Development Guidelines
- **Ansible:** Use roles. Keep vars in `group_vars`/`host_vars`. 
- **Terraform:** Modules in `cloud/terraform/modules/`.