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
- Multi-cluster (2026-09-24): `-kubeconfig=/etc/headlamp-kubeconfig/config` + a read-only secret volume `headlamp-pcluster-kubeconfig` (key `config`). Second cluster API is `192.168.9.16:6443`, verified REACHABLE from pods.
- **Secret-volume permission gotcha:** a secret volume with a restrictive `defaultMode` (e.g. `0400`) mounted into a container whose `runAsUser` is NOT root, with NO pod-level `fsGroup`, is **unreadable** -- kubelet leaves it root:root, so the app logs `open <path>: permission denied`. Fix = add pod-level `securityContext.fsGroup: <runAsUser's gid>`, which chowns the secret to group fsGroup and grants group read (0400 -> readable). Verified empirically. Contrast: for **hostPath** volumes fsGroup does NOT help (see [[seerr-v3-non-root-image]]); it works only for secret/configmap/emptydir volumes.
- Log line `loading dynamic kubeconfig ... /tmp/.config/Headlamp/kubeconfigs/config: no such file or directory` is benign -- "Dynamic clusters support: false", that optional path is simply absent.
