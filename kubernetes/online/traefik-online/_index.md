# Traefik (online instance)

Second, intentionally **isolated** Traefik used to serve the public-facing
`online` namespace (`toggle.la1r.com` via service-toggle). It must never
overlap with the main instance (`kubernetes/traefik/`).

Current version: **Traefik v3.7.13**.

## Isolation model
| | main (`traefik`) | online (`online`) |
|---|---|---|
| LoadBalancer VIP | `192.168.6.2` | `192.168.6.129` |
| IngressClass | `lan` (default) | `online` |
| CRD provider | `expose!=online` (all namespaces) | `expose=online`, `namespaces=online`, `allowCrossNamespace=false` |
| TLS | cert-manager (`traefik-bas`) | ACME resolver (`acme.json`, storage on PVC) |

Both instances use the same `traefik.io` CRDs (cluster-scoped). Isolation is
enforced by the provider label selector + namespace scoping, and by separate
ServiceAccounts/ClusterRoles. Verified: `toggle.la1r.com` is served **only** by
the online instance (main returns 404) and internal `*.bas` apps are **not**
reachable through the online VIP.

## Files
- `traefik-online.yml` — Deployment (v3.7.13), Services, IngressClass `online`.
  Dashboard `--api.insecure` was removed; no `admin:8080` is exposed.
- `traefik-online-rbac.yml` — dedicated ClusterRole/Binding; Traefik v3 also
  needs `configmaps` + `nodes` read access.
- `pv/` — PVC for the ACME `acme.json` storage.

## Apply
```
kubectl apply -k kubernetes/online/traefik-online/
```

## Public access
In front of the online VIP, a router/firewall port-forward exposes ports 80/443
(the online instance is the cluster's public edge). Only resources labelled
`expose=online` in the `online` namespace are published.