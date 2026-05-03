---
name: Headlamp deployment
description: Headlamp Kubernetes UI replacing kubernetes-dashboard, with Authentik forwardAuth middleware
type: reference
---

Headlamp deployed in `headlamp` namespace, replacing the deprecated `kubernetes-dashboard` at kubernetes.bas.

**Key configurations:**
- Image: `ghcr.io/headlamp-k8s/headlamp:v0.30.0`
- Port: 4466 (HTTP, no TLS internally)
- Authentication: Authentik forwardAuth middleware (`authentik-headlamp`), no OIDC config in Headlamp itself
- RBAC: headlamp SA gets cluster-admin via `headlamp-admin` ClusterRoleBinding
- Authentik OIDC groups: `admins` -> cluster-admin, `viewers` -> view (via `authentik-admins` and `authentik-viewers` ClusterRoleBindings)
- IngressRoute uses Traefik `traefik.containo.us/v1alpha1` (not standard networking ingress)
- Domain: kubernetes.bas, TLS cert: kubernetes-bas-tls, ClusterIssuer: la1r
- No ServersTransport needed (Headlamp serves plain HTTP)

**Gotchas:**
- Headlamp needs writable filesystem (`readOnlyRootFilesystem: false`) -- it creates config in `/.config` and temp files in `/tmp`
- Headlamp requires the `USER` env var set (else it errors with "user: Current requires cgo or $USER set in environment")
- The kubeconfig file errors in logs ("/.kube/config: no such file or directory") are non-fatal -- Headlamp falls back to in-cluster service account auth
