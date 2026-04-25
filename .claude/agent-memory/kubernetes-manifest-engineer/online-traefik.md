---
name: Online Traefik Pattern
description: Dedicated Traefik ingress controller for the online namespace, with label-selector-based CRD discovery
type: reference
---

A separate Traefik v2.9 instance was deployed in the `online` namespace to isolate public-facing services from the main Traefik instance (in the `traefik` namespace).

**Label selector pattern**: The online Traefik uses `--providers.kubernetesCRD.labelselector=expose=online` to only pick up IngressRoute/Middleware resources that carry the label `expose: "online"`. This means resources in the `online` namespace need to opt-in to the online Traefik.

**Resource naming**: All resources use the prefix `online-traefik-ingress-controller` for consistency (ServiceAccount, ClusterRole, ClusterRoleBinding, Deployment).

**Key differences from main Traefik**:
- Image: `traefik:v2.9` (older than main)
- Restricts CRD discovery to only the `online` namespace
- Uses label selector `expose=online` for CRD discovery
- Has `allowCrossNamespace=false` set
- LoadBalancer IP: `192.168.6.129` (main uses `192.168.6.2`)
- Prometheus annotations use custom `seb_scrape: "true"` instead of `prometheus.io/scrape`

**NetworkPolicy pattern**: When moving a service to a same-namespace Traefik, the NetworkPolicy must add a second ingress rule allowing traffic from pods with label `k8s-app: online-traefik-ingress-lb` in the same namespace, in addition to the existing cross-namespace rule.
