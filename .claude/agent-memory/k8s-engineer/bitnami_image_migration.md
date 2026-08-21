---
name: bitnami-image-migration
description: Bitnami free Docker Hub images removed Aug 2025; old tags moved to bitnamilegacy (unmaintained, may vanish); e.g. bitnami/kubectl:1.31 → bitnamilegacy/kubectl:1.31
metadata:
  type: reference
---

Bitnami deprecated its free `docker.io/bitnami/*` images on Docker Hub effective 2025-08-28. Old Debian-based tags moved to `docker.io/bitnamilegacy/*`, where they receive NO security updates and may be removed at any time (search results mention ~2025-09-29 removal for some tags). `docker.io/bitnami/*` tags now fail with ImagePullBackOff/ErrImagePull.

**Why:** Repo manifests that pin `bitnami/kubectl:1.31` (e.g. workflows/cleanup/cleanup-completed-pods.yaml) break on new pulls.

**How to apply:**
- Verify a tag still exists before relying on it: `curl -s "https://hub.docker.com/v2/repositories/bitnamilegacy/kubectl/tags/?page_size=100"` (paginate — 1.31 tags were on page 2, not page 1; the filter must scan all pages).
- USER PREFERENCE: do NOT use `bitnamilegacy/*` (unmaintained, user explicitly rejected it for the cleanup cronjob). For kubectl scripts needing bash+jq+kubectl, use **`alpine/k8s:<kubectl-version>`** (actively maintained by the Alpine project, contains bash+jq+kubectl). workflows/cleanup/cleanup-completed-pods.yaml now pins `alpine/k8s:1.33.11` (matches cluster server version). Prefer pinning a specific tag matching the cluster's kubectl minor, never `latest`.
- Verify in-cluster: `sudo crictl pull docker.io/alpine/k8s:1.33.11` then `sudo ctr -n k8s.io run --rm docker.io/alpine/k8s:1.33.11 t sh -c "which bash jq kubectl"`.
- `registry.k8s.io/kubectl:<vX.Y.Z>` is distroless (no bash/jq) — unsuitable for scripts that shell out to bash/jq. No in-cluster registry mirror is configured on jay-c (containerd pulls Docker Hub directly). Related: [[cluster-pki-certs]] [[node-registry-dns]]
