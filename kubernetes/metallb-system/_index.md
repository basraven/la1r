# MetalLB

Load balancer for bare-metal Kubernetes. Announces the `192.168.6.0/24` VIP pool
via layer-2 (ARP/NDP).

Current version: **v0.16.1** (controller + speaker).

## Manifests
- `manifests/metallb-native.yaml` — **vendored** render of the upstream
  `config/native` base:
  ```
  kubectl kustomize github.com/metallb/metallb/config/native?ref=v0.16.1 > manifests/metallb-native.yaml
  ```
  Committed so the cluster is rebuildable offline and `git diff` shows real
  upgrades. When upgrading, re-render and keep the `# source:` header.
- `kustomization.yml` — applies `manifests/metallb-native.yaml` plus
  `metallb-installation.yml`, and **patches** the controller/speaker ClusterRoles
  with `create` on `tokenreviews` / `subjectaccessreviews` (the upstream native
  base omits the RBAC MetalLB's own metrics server needs — see below).
- `metallb-installation.yml` — `IPAddressPool first-pool`
  (`192.168.6.1-192.168.6.254`) + `L2Advertisement`.
- `namespace.yml`, `cluster-admin.yml` — historical.
- `example/` — sample LoadBalancer Services.

## Metrics (v0.16 breaking change)
Since v0.16 MetalLB serves metrics over **HTTPS only** (self-signed cert) on port
`9120`, protected by **native TLS + RBAC** (no more kube-rbac-proxy): a bearer
token authorized for the non-resource URL `/metrics` is required. For Prometheus
scraping to work you need all three of:
1. the dedicated `metallb` scrape job (`scheme: https`,
   `insecure_skip_verify`, token from Prometheus's ServiceAccount) in
   `kubernetes/monitoring/prometheus/config/prometheus-config.yml`;
2. the `prometheus-metallb-metrics` ClusterRole/Binding in
   `kubernetes/monitoring/prometheus/prometheus-rbac.yml`;
3. the controller/speaker RBAC to create `tokenreviews`/`subjectaccessreviews`
   (applied by the kustomization patch above).

Without these, `/metrics` fails with TLS-handshake or HTTP 401/500 and no
`metallb_*` series appear.

## Apply
```
kubectl apply -k kubernetes/metallb-system/
```

## Troubleshooting / status
- `kubectl get servicel2statuses -n metallb-system`
- `kubectl get ipaddresspools,l2advertisements -n metallb-system`
- `kubectl get svc -A --field-selector spec.type=LoadBalancer`