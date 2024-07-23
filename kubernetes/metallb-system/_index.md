# MetalLB before installation
1. kubectl edit configmap -n kube-system kube-proxy
2. Set:
   ```yaml
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    kind: KubeProxyConfiguration
    mode: "ipvs"
    ipvs:
        strictARP: true
   ```
> Source: https://metallb.universe.tf/installation/