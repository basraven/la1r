---
name: Traefik API group is traefik.containo.us (not traefik.io)
description: This cluster uses the older traefik.containo.us API group for Middleware/IngressRoute CRDs, not the newer traefik.io group.
type: reference
---

This cluster runs Traefik v2 (classic) which uses the `traefik.containo.us/v1alpha1` API group for CRDs (Middleware, IngressRoute, etc.), NOT the newer `traefik.io/v1alpha1` (provider-based) API group.

**Why this matters:** Middleware and IngressRoute resources created with `apiVersion: traefik.io/v1alpha1` will be silently rejected by the API server (CRD does not exist), causing Traefik to fail to build routes that reference them.

**How to apply:** All Traefik CRD manifests must use `apiVersion: traefik.containo.us/v1alpha1`. The standard Kubernetes Ingress resources (networking.k8s.io/v1) work fine with Traefik in this cluster regardless.
