---
name: Headlamp OIDC login loop
description: Headlamp K8s dashboard at kubernetes.bas has OIDC login loop — kube-apiserver needs OIDC flags
type: project
---

Headlamp dashboard at https://kubernetes.bas/ has a persistent login loop.

**OIDC login works** (Authentik SSO redirect succeeds), but all kube-apiserver data API calls return 401, causing Headlamp to log out and redirect back to the login screen.

**Root cause:** The kube-apiserver is not configured with OIDC flags (`--oidc-issuer-url`, `--oidc-client-id`, etc.) in the kubeadm config template at `cicd/ansible/roles/kubernetes-init/templates/kubeadm-config.yml.j2`. Headlamp passes the user's OIDC token to kube-apiserver, which rejects it without OIDC configuration.

The `/etc/hosts` fix (auth.la1r.com resolution) is already in place. RBAC bindings for OIDC groups (`admins`/`viewers`) exist in `kubernetes/headlamp/rbac-authentik.yml` but are non-functional until the API server validates OIDC tokens.

**Key evidence:** `/clusters/main/version` and `/clusters/main/healthz` return 200 (kube-apiserver is reachable and healthy), but all `/clusters/main/api/v1/*` endpoints return 401.
