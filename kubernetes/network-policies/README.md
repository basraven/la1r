# Network policies

Default-deny ingress segmentation for the la1r cluster, so that a compromised
pod cannot freely reach other pods/services (previously the network was flat).

## Baseline (every covered namespace)
Each namespace gets:

- `default-deny-ingress` — drop all ingress not matching the allow below.
- `allow-ingress` — permit traffic from:
  - `podSelector: {}` (same-namespace app links, e.g. the *arr stack:
    sonarr/radarr/bazarr/jellyseerr ↔ jackett/qbittorrent, app ↔ its DB/redis)
  - ingress controllers: namespaces `traefik` and `online`
  - `monitoring` (Gatus cross-namespace probes + Prometheus scraping)
  - node network `192.168.5.0/24` (kubelet liveness/readiness probes and
    LoadBalancer traffic SNAT'd by kube-proxy for `externalTrafficPolicy:
    Cluster` services)

## Covered namespaces (file → namespaces)
| File | Namespaces |
|---|---|
| `dns.yaml` | dns (Pi-hole: DNS 53 open to all; web/API only for controllers + local + node) |
| `security.yaml` | security (authentik, vaultwarden) |
| `monitoring.yaml` | monitoring |
| `baseline-apps.yaml` | ai, crm, development, headlamp, media, nextcloud, storage, torrent, workflows, poolbuyr-runner, **cert-manager**, **metallb-system** |
| `gaming.yaml` | gaming (+ game LB ports 15637/tcp, 27015/udp from anywhere — `externalTrafficPolicy: Local`) |
| `vpn.yaml` | vpn (+ WireGuard 51820/udp from anywhere — LB `Local`) |
| `registry.yaml` | registry (+ 5000 from pod CIDR `10.244.0.0/16` and the node for image pulls) |

`cert-manager` / `metallb-system` are covered too: the node-network allow lets
the kube-apiserver (hostNetwork) reach the admission webhooks, and `monitoring`
covers their scrape targets.

## Deliberately not covered
- `traefik`, `online` — public ingress edge; must accept external traffic.
- `kube-system`, `calico-system`, `tigera-operator`, `local-path-storage` — system.
- `homeautomation`, `ansible` — no running workloads.
- `default` — only throwaway pods.

## Hidden app-to-app connections
Policies only secure ingress. App-to-app connections configured **inside**
applications must target either the same namespace (allowed by the baseline) or
an external host (egress, unrestricted). Any **cross-namespace** in-cluster
integration must be whitelisted here explicitly. To observe traffic before
adding new default-deny:

- Calico flow logs via **Goldmane + Whisker** would show denied flows, but they
  require the Calico API server (`projectcalico.org/v3`), which this cluster
  does not run. Install `calico-apiserver` if you want that visibility, then
  re-add `calico/flow-logs.yaml` (Goldmane + Whisker CRs).

## Verify after changes
Pods `Ready` (kubelet probes), Gatus checks green, all Prometheus targets up,
e2e ingress (`auth.la1r.com`, `traefik.bas`, app UIs), DNS resolution.