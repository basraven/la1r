---
name: registry-cronjob
description: registry-cleanup CronJob (kubernetes/registry/registry-cleanup.yaml) prunes in-cluster registry to newest tag/repo; first success 2026-08-21 03:00; GC step fails on RBAC (Role lacks deployments get)
metadata:
  type: project
---

In-cluster registry (ns `registry`, svc `registry.registry.svc.cluster.local:5000`, HTTPS-only with private CA) is pruned daily 03:00 by CronJob `registry-cleanup`. It keeps only the newest-created tag per repo and deletes the rest, then runs `registry garbage-collect --delete-untagged=true`.

**Why:** The registry accumulates many tags per repo (builds, `latest`, version tags). The job had NEVER succeeded since it was added — root cause was `--insecure` passed to regctl commands (flag never existed; the correct form is `regctl registry set "$REGISTRY" --tls insecure`, value `insecure` = skip cert verify, NOT `tls disabled`), plus the regctl download was unpinned (`releases/latest`). Fixed 2026-08-20 in kubernetes/registry/registry-cleanup.yaml (pinned v0.11.5). First successful run: 2026-08-21T03:00:08Z (job registry-cleanup-29788020, Complete 1/1).

**How to apply:**
- regctl with private-CA HTTPS registry: must `regctl registry set <host> --tls insecure` first; then plain `regctl repo ls` / `tag ls` / `image config` / `tag rm` (NO `--insecure` flag).
- READ-ONLY inspection: run a throwaway pod (alpine:3.20 + pinned regctl v0.11.5) in ns registry; capture `regctl tag ls` + `regctl image config <ref> | jq -r '.created'` + `regctl manifest digest <ref>` per tag.
- GC RBAC FIXED 2026-08-21: Role `registry-cleanup` now also grants `apiGroups: [apps], resources: [deployments], verbs: [get]` (kubectl exec on deployment/registry needs it). Verified with `kubectl auth can-i get deployments -n registry --as=system:serviceaccount:registry:registry-cleanup` → yes. First GC that ran successfully deleted 194 untagged blobs (job registry-cleanup-gc-verify, Complete 1/1, `=== Registry cleanup complete ===`, no RBAC Forbidden).
- In-use images as of 2026-08-21 (all preserved by the prune): `claudecodeui:v4`, `openvscode-server:v2`, `ubuntu-xfce4:v1` (dev workloads; openvscode/ubuntu scaled to 0 by Sablier). Related: [[cluster-pki-certs]] [[bitnami-image-migration]]
