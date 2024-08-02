# Installing
1. First run `kubernetes_init` and `kubernetes_fetch` in /cicd/ansible to init the cluster with kubeadm
2. Untaint the kubernetes master node with: `kubectl taint nodes --all node-role.kubernetes.io/control-plane-`
3. Then apply calico: `kubectl apply -k kubernetes/calico`
3. Then apply calico: `kubectl apply -k kubernetes/calico`
4. Run `kubeadm token create --print-join-command` on the main node and join with secondary nodes
5. Then install flux locally and run `kubernetes/flux/deploy.sh`
6. Then apply `kubernetes/storage/node-labels/node-labels.sh`