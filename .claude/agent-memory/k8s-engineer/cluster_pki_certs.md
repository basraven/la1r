---
name: cluster-pki-certs
description: la1r cluster is kubeadm-based with 1-year PKI certs expiring annually; renewal applied 2026-08-20; kubeadm v1.33.11 ignores certificateValidityDuration in v1beta4; admin kubeconfig at ~/.kube-la1r/config
metadata:
  type: project
---

The la1r cluster was created with kubeadm (control plane: jay-c, 192.168.5.3, kube-vip IP also 192.168.5.100). All kubeadm PKI certs have a 1-year lifetime. When expired, the apiserver still serves but every TLS client rejects it — kubectl fails with "certificate has expired", and kube-controller-manager + kube-scheduler go effectively dead (informer/list/watch TLS failures). Consequence: Deployment controller cannot reconcile — deployments stuck with replicas>0 but no pod. This happened 2026-08-17 and was fixed 2026-08-20.

**Why:** kubeadm static-pod certs do not auto-renew (only kubelet certs do). Nothing in this repo automates annual renewal — the admin kubeconfig is fetched via cicd/ansible/roles/kubernetes-fetch. Recurrence expected yearly unless automated.

**How to apply:**
- Fix applied 2026-08-20: `sudo kubeadm certs renew all --config=/etc/kubernetes/kubeadm-config.yaml` on jay-c, delete static pods (`crictl rmp -f <id>` for apiserver/etcd/controller-manager/scheduler — also remove stale NotReady duplicate pods), `systemctl restart kubelet`. Control plane came back clean with no crash-loops.
- IMPORTANT: kubeadm v1.33.11 does NOT support `certificateValidityDuration` in ClusterConfiguration (v1beta4 strict-decoding error "unknown field"). Attempting it renews certs with default 1-year anyway (warning only). To get long-lived admin access, mint a 10-year client cert signed by the still-valid CA (valid to 2035) and swap client-certificate-data/client-key-data into admin.conf: openssl genrsa 2048, req with subject `/CN=kubernetes-admin/O=system:masters`, extfile with `extendedKeyUsage=clientAuth` + `keyUsage=digitalSignature,keyEncipherment`, `openssl x509 -req -CA ca.crt -CAkey ca.key -days 3285 -extfile`; replace the two base64 fields via python. CA data + server field stay intact. Result: admin.conf client cert valid to 2035-08-18, server certs to 2027-08-20.
- After renewal, refresh local kubeconfig: copy jay-c `/etc/kubernetes/admin.conf` over root-owned `~/.kube-la1r/config` (needs sudo, chmod 600) after backing it up first (`cp ~/.kube-la1r/config ~/.kube-la1r/config.bak.<date>`).
- Diagnostic access when admin certs are expired: SSH to jay-c (`ssh -i ~/.ssh-la1r/id_rsa basraven@192.168.5.3`) and either (a) inspect containers via `sudo crictl ps -a` / `sudo crictl logs <id>`, or (b) mint a throwaway client cert signed by /etc/kubernetes/pki/ca.key (CN=diag, O=system:masters) into /tmp and run `kubectl --kubeconfig ... --insecure-skip-tls-verify` — read-only, works even with the expired apiserver serving cert.
- User CLI config lives at ~/.kube-la1r/config (not ~/.kube); host paths ~/.ssh-la1r override ~/.ssh per CLAUDE.md.
- Kubelet client cert is kubelet-rotated (`/var/lib/kubelet/pki/kubelet-client-current.pem`), NOT controlled by `kubeadm certs renew`; kubelet.conf references it by file path, no embedded cert.
- There is an existing `/etc/kubernetes/kubeadm-config.yml` (v1beta3, controlPlaneEndpoint 192.168.5.100:443, OIDC args) — different from the `.yaml` created during the fix. Leave it; admin.conf/apiserver manifest use 192.168.5.3:6443.
- crictl on jay-c emits `Config "/etc/crictl.yaml" does not exist` warnings but still works via default endpoints — harmless.
