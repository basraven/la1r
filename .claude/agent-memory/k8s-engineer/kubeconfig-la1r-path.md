---
name: kubeconfig-la1r-path
description: la1r admin kubeconfig lives at ~/.kube-la1r/config (the dir ~/.kube-la1r itself is not a kubeconfig file)
metadata:
  type: reference
---

The la1r cluster admin kubeconfig is `/home/basraven/.kube-la1r/config`. `~/.kube-la1r` is a directory (root-owned) containing `config` plus a dated `config.bak.*`. Use `kubectl --kubeconfig ~/.kube-la1r/config`; pointing kubectl at `~/.kube-la1r` (the directory) fails with "is a directory". Context name is `kubernetes-admin@kubernetes`.

This complements the CLAUDE.md rule to prefer `~/.kube-la1r` over `~/.kube` — but you must append `/config` to the path.

**Why:** First kubectl attempt errored because the host-config note says "use ~/.kube-la1r", but the CLI needs the file, not the folder.

**How to apply:** Whenever running kubectl against the la1r cluster in this repo, pass `--kubeconfig /home/basraven/.kube-la1r/config`.
