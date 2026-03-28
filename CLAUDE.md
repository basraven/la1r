# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository (`la1r`) is a homelab infrastructure codebase managing Kubernetes applications, configuration management (Ansible), cloud infrastructure (Terraform), a Go-based hardware control server (`switch-server`), a kiosk raspberry pi dashboard, and Hugo documentation.

Key components:
- **Kubernetes manifests** for deploying services in a home lab cluster
- **Go application** (`switch-server`) for controlling GPIO hardware (e.g., switches, PWM)
- **Ansible** for configuration management of physical hosts
- **Terraform** for provisioning cloud resources
- **Kiosk application** built with the `opencode` agent framework
- **Hugo static site** for documentation

## Directory Structure

```
├── kubernetes/              # Kubernetes manifests for all applications
│   ├── <app>/              # Each application has its own directory
│   │   ├── <app>.yml       # Single YAML with Deployment, Service, Certificate, Ingress
│   │   ├── kustomization.yaml
│   │   └── pv/             # Persistent volume claims and volumes
├── src/golang/switch-server/   # Go hardware control server
├── src/kiosk/              # Kiosk Raspberry Pi Dashboard
├── cicd/ansible-new/       # Ansible roles and playbooks
├── cloud/terraform/        # Terraform modules and environments
├── documentation/          # Hugo documentation site
├── credentials/            # Sensitive credentials (NEVER access/modify)
└── .deprecated/            # Deprecated code (ignore)
```

## Common Commands

### Kubernetes
- Apply an app: `kubectl apply -k kubernetes/<app>/`
- View logs (write to file): `kubectl logs -n <namespace> <pod> > logs.txt`
- Restart deployment: `kubectl rollout restart deployment/<app> -n <namespace>`
- Never use `kubectl patch`; always modify YAML files.

### Go Project (`switch-server`)
- Development shell: `./dev.sh` (starts Go container)
- Build for AMD64: `./build-amd64.sh`
- Build for ARM7: `./build-arm7.sh`
- Run tests: `docker run --rm -v $PWD:/app -w /app golang:1.23-alpine go test ./...`
- Single test: `go test -v -run <TestName> ./path/to/pkg` (inside dev container)

### Ansible
- Run playbook: `./ansible.sh`
- Dry run (check mode): `./ansible-dry-run.sh`
- Use tags: `ansible-playbook -i inventory/hosts.yml site.yml --tags "nfs,haproxy"`
- Limit to hosts: `ansible-playbook -i inventory/hosts.yml site.yml --limit "linux-wayne"`
- Never modify `site.yml` or `inventory/hosts.yml` without explicit confirmation.

### Terraform
- Apply environment: `cd cloud/terraform/environments/<env>/<subenv>/ && ./apply.sh`
- Uses AWS_PROFILE environment variable (e.g., `AWS_PROFILE=la1r-root-root-admin`).
- Reusable modules in `cloud/terraform/modules/`

### Documentation (Hugo)
- Development server: `cd documentation/src/ && ./dev.sh`
- Populate external docs: `./populate-external-docs.sh` (called automatically)

### Kiosk Application
- Run with Docker: `docker run --rm -v $PWD/.opencode:/root/.opencode -it ghcr.io/anomalyco/opencode`
- Configuration in `.opencode/opencode.json`

## Kubernetes Patterns

**Manifest Structure:**
- Each app's main manifest (`<app>.yml`) contains all resources separated by `---`.
- Order: Deployment → Service → Certificate → Ingress.
- Persistent volumes go in `pv/` subdirectory with its own `kustomization.yaml`.
- The root `kustomization.yaml` references main manifests and `pv/kustomization.yaml`.

**Ingress Configuration:**
- Use `apiVersion: networking.k8s.io/v1`.
- Name suffix: `-https` (e.g., `monica-https`).
- Annotations:
  - `traefik.ingress.kubernetes.io/router.tls: "true"`
  - `traefik.ingress.kubernetes.io/router.entrypoints: "websecure"`
  - Middleware references: `<namespace>-sablier-<app>@kubernetescrd`
- TLS secret matches the Certificate resource.

**Certificates:**
- Use cert-manager `Certificate` resource.
- `issuerRef` points to ClusterIssuer `la1r`.
- `secretName` matches Ingress TLS secret.

**Namespace:**
- Every resource explicitly sets `namespace:`.
- Namespaces are defined in `kubernetes/<app>/namespace.yml`.

## Go Project Guidelines

**Code Structure:**
- `cmd/switch-server/main.go`: Application entrypoint.
- `http/v1/`: API routes and handlers (Gin framework).
- `internal/`: Shared logic not exported (e.g., hardware abstraction).
- `models/`: Centralized data structures.

**Style:**
- Follow standard Go idioms.
- Package names: single word, lowercase.
- Variable naming: `camelCase` locals, `PascalCase` exported.
- Error handling: mandatory `if err != nil` checks; prefer returning errors over `log.Fatal` in libraries.
- Imports grouped: standard library, external packages, internal packages.

**Logging:**
- Use `log` package with custom flags (date/time/shortfile).

## Ansible Guidelines

**Organization:**
- Use roles for modularity.
- Variables in `group_vars`/`host_vars`, not hardcoded in tasks.
- Work only within `ansible-new/` directory.

## Terraform Guidelines

**Structure:**
- Environment-based layouts under `environments/`.
- Reusable modules in `modules/`.
- Backend configuration in `backend.tf`.

## Kiosk Application

- Built with `opencode` agent framework.
- Core configuration in `.opencode/opencode.json`.
- Run inside Docker container for development.

## Documentation

- Built with Hugo; content in `documentation/src/content/docs/`.
- Development server runs locally.
- External docs populated via script.

## Important Rules

- **NEVER** access or modify files in `credentials/` or `.deprecated/` folders.
- **NEVER** execute `git` commands; let the user handle them manually.
- When troubleshooting Kubernetes, write `kubectl logs` output to a file instead of streaming to stdout.
- **Security**: Never expose secrets, API keys, or credentials in code or logs.
- **Ignore**: `.deprecated`, `.git`, `.windsurfrules`, and `credentials` folders.

## Troubleshooting

- **K8s connectivity**: Check Traefik middleware and Ingress annotations.
- **GPIO issues**: Check `switch-server` logs for hardware-pwm errors.
- **Ansible failures**: Use `./ansible-dry-run.sh` to check syntax.

## Workflow Examples

1. **Adding a Kubernetes app:**
   - Create `kubernetes/<app>/` directory.
   - Add `<app>.yml` with Deployment, Service, Certificate, Ingress.
   - Add `kustomization.yaml` referencing all manifests and `pv/`.
   - Create `pv/` directory with PVC/PV manifests and its own `kustomization.yaml`.

2. **Updating switch-server:**
   - Modify `internal/` or `http/` code.
   - Build with `build-amd64.sh` or `build-arm7.sh`.
   - Deploy using appropriate method (manual or CI).

3. **Updating documentation:**
   - Add markdown files to `documentation/src/content/docs/`.
   - Run `dev.sh` to preview.

---

*Based on AGENTS.md and .windsurfrules. Last updated 2026-03-28.*