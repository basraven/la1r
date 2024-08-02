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
3. Run ` kubectl label node linux-wayne node.kubernetes.io/exclude-from-external-load-balancers-
node/linux-wayne unlabeled` to make sure you can host an LB