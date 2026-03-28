# Agent Guide: la1r Project

This document serves as the source of truth for agentic coding agents operating in this repository. Follow these guidelines strictly.

## 🛞 Core Principles (Windsurf Integration)
- Always start replies with ✅ to indicate understanding of the root rules.
- Ignore `.deprecated`, `.git`, `.windsurfrules`, and `credentials` folders.
- NEVER access or modify files in `credentials/` or `.deprecated/` folders from the project root.
- Never execute `git` commands; let the user handle them manually.
- When troubleshooting Kubernetes, write `kubectl logs` output to a file instead of streaming to stdout.
- Security: Never expose secrets, API keys, or credentials in code or logs.

---

## ☸️ Kubernetes Guidelines
Located in `/kubernetes/`.
- **Structure**: Each app has its own directory: `/kubernetes/<app>/`.
- **Manifests**: Use a single `<app>.yml` for Deployment, Service, Certificate, and Ingress.
- **Resource Order**: Deployment → Service → Certificate → Ingress.
- **PV/PVC**: Always place in `/kubernetes/<app>/pv/` with its own `kustomization.yml`.
- **Kustomize**: The app root MUST have a `kustomization.yml` referencing all manifests and the `pv/` directory.
- **Ingress**:
  - Always use `apiVersion: networking.k8s.io/v1`.
  - Name suffix: `-https` (e.g., `monica-https`).
  - Annotations: 
    - `traefik.ingress.kubernetes.io/router.tls: "true"`
    - `traefik.ingress.kubernetes.io/router.entrypoints: "websecure"`
    - Middleware: Reference namespaced middleware: `<namespace>-sablier-<app>@kubernetescrd`.
- **Certificates**: Use cert-manager's `Certificate` resource; `secretName` must match.
- **Commands**:
  - **Apply**: `kubectl apply -k kubernetes/<app>/`
  - **Logs**: `kubectl logs -n <ns> <pod> > logs.txt`
  - **Restart**: `kubectl rollout restart deployment/<app> -n <ns>`
  - **Note**: Never use `kubectl patch`. Always use YAML files for changes.

---

## 🐹 Go Project (switch-server)
Located in `/src/golang/switch-server/`.
- **Style**:
  - Follow standard Go idioms.
  - Package names: single word, lowercase (e.g., `models`, `handlers`).
  - Variable naming: `camelCase` for local, `PascalCase` for exported.
  - Error handling: Mandatory `if err != nil` checks. Prefer returning errors over `log.Fatal` in libraries.
- **Structure**:
  - `cmd/`: Application entrypoints (e.g., `switch-server/main.go`).
  - `http/v1/`: API routes and handlers (using Gin framework).
  - `internal/`: Shared logic not meant for external use (e.g., hardware abstraction).
  - `models/`: Centralized data structures.
- **Commands**:
  - **Dev**: `./dev.sh` (runs Go in Docker container).
  - **Build (AMD64)**: `./build-amd64.sh`
  - **Build (ARM7)**: `./build-arm7.sh`
  - **Test**: `docker run --rm -v $PWD:/app -w /app golang:1.23-alpine go test ./...`
  - **Single Test**: `go test -v -run <TestName> ./path/to/pkg` (inside dev container).

---

## 🏗️ Ansible Guidelines
Located in `/cicd/ansible-new/`.
- **Usage**: Always use `./ansible.sh` or `./ansible-dry-run.sh`.
- **Restrictions**: NEVER modify `site.yml` or `inventory/hosts.yml` without explicit confirmation.
- **Organization**: Use roles for modularity. Work ONLY within the `ansible-new/` directory.
- **Variables**: Use `group_vars` or `host_vars` instead of hardcoding in tasks.

---

## ☁️ Terraform Guidelines
Located in `/cloud/terraform/`.
- **Structure**: Environment-based layouts (e.g., `environments/root/prod/`).
- **Commands**: Use the `apply.sh` script within the environment directory.
- **Modularity**: Place reusable logic in `/cloud/terraform/modules/`.
- **State**: Backend configuration is typically handled in `backend.tf`.

---

## 📺 Kiosk Application
Located in `/src/kiosk/`.
- **Environment**: Developed using the `opencode` agent framework.
- **Commands**: 
  - **Run (Docker)**: `docker run --rm -v $PWD/.opencode:/root/.opencode -it ghcr.io/anomalyco/opencode`
- **Structure**: Core configuration in `.opencode/opencode.json`.

---

## 📚 Hugo Documentation
Located in `/documentation/`.
- **Commands**:
  - **Dev Server**: Run `./dev.sh` from `/documentation/src/`.
  - **Populate Docs**: `./populate-external-docs.sh` is called automatically.
- **Content**: Markdown files in `src/content/docs/`.

---

## 🛠️ Error Handling & Style
- **Logging**: In Go, use the `log` package with custom flags (date/time/shortfile).
- **Comments**: Focus on "why". Use `FIXME` and `TODO` for known technical debt.
- **Imports**: Group into standard library, external packages, and internal packages.
- **Shell Scripts**: Use `#!/bin/bash` and ensure proper error checking (`set -e`).

---

## 🚀 Common Workflows
1. **Adding a K8s App**: Create `kubernetes/<app>/`, add `<app>.yml` (D->S->C->I), add `kustomization.yml`.
2. **Updating Switch Server**: Modify `internal/` or `http/`, build using `build-amd64.sh` or `build-arm7.sh`.
3. **Updating Docs**: Add `.md` to `documentation/src/content/docs/`, run `dev.sh` to preview.

---

## 🔍 Troubleshooting
- **K8s Connectivity**: Check Traefik middleware and Ingress annotations.
- **GPIO Issues**: Check `switch-server` logs for hardware-pwm errors.
- **Ansible Failures**: Use `./ansible-dry-run.sh` to check for syntax errors.
