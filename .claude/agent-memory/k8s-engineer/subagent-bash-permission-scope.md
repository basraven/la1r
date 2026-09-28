---
name: subagent-bash-permission-scope
description: When k8s-engineer runs as a delegated subagent it can only run allowlisted kubectl verbs; apply/rollout/wait/exec die with "Tool permission request failed: AbortError: Stream closed"
metadata:
  type: reference
---

When the `k8s-engineer` agent is spawned as a subagent (e.g. from the claudecodeui session), the interactive permission prompt channel is closed. Any Bash command that is not already in `.claude/settings.local.json` `permissions.allow` fails instantly with:

```
Tool permission request failed: AbortError: Stream closed
```

Verbs that DO work (prefix-matched from the allowlist): `kubectl get ...`, `kubectl logs ...`, `kubectl describe ...`, `kubectl events ...`, `kubectl delete job ...`.

Verbs that FAIL: `kubectl apply -k`, `kubectl rollout restart`, `kubectl wait`, `kubectl exec`, `kubectl create`, `kubectl config ...`.

Also sandboxed: reads/writes outside the repo working directory. `ls /tmp`, `ls /home/basraven`, `env | grep`, and shell redirection to `/tmp` all fail the same way. Reads *inside* `/home/basraven/projects/la1r` work.

**Why:** Discovered 2026-09-28 trying to rebuild `kubernetes/development/opencode` (image v1 -> v2). The task could not be performed: no apply, no rollout, no exec verification. `kubectl --kubeconfig /home/basraven/.kube-la1r/config get ...` worked fine, so the cluster itself was reachable — only the un-allowlisted verbs were blocked.

Re-run of the same task on 2026-09-28 (second delegation, a few hours later) was blocked identically. This is a persistent property of the subagent permission channel, not a transient glitch — do not burn retries on it, report back immediately.

**How to apply (staleness check that works read-only):** to tell whether a fixed-name kaniko build Job is stale without applying anything, compare `kubectl get job <name> -n <ns> -o jsonpath='{.status.completionTime}'` against the `Dockerfile` mtime in the repo, and confirm the pushed destination in the job `spec` args against the Deployment `.spec.containers[0].image` and the pod `.status.containerStatuses[0].imageID`.

**How to apply:** Before promising a subagent-driven deploy that needs `kubectl apply`, check whether the verb is in `.claude/settings.local.json` allow list. If it is not, either ask the user to add it, or have the user/parent run the apply step itself. `kubectl delete job` IS allowed, so never delete a fixed-name build Job as a "prep" step you cannot undo with a re-apply. See [[kubeconfig-la1r-path]].
