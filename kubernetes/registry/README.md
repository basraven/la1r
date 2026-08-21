# Internal OCI Container Registry

In-cluster container registry replacing init-container apt installs at pod startup. Images are built via kaniko Jobs and pushed to this registry over HTTPS (TLS via cert-manager).

## Prerequisites: Node DNS must route cluster.local to CoreDNS

The kubelet/containerd uses the node's DNS to resolve image names. Since
`registry.registry.svc.cluster.local` is an in-cluster name only CoreDNS knows,
the node must be configured to forward `cluster.local` queries to CoreDNS.

This is handled by Ansible (`cicd/ansible/roles/kubernetes-init/tasks/configure-registry-access.yml`):

1. systemd-resolved routes `~cluster.local` on `enp4s0` to CoreDNS (10.96.0.10)
2. Kubelet `resolvConf` points to the systemd-resolved stub (`/run/systemd/resolve/stub-resolv.conf`)

Without this, new image tag rollouts fail with `ImagePullBackOff` — DNS
resolution of `registry.registry.svc.cluster.local` fails from the node.

## How it works

```
ConfigMap (Dockerfile)  ->  kaniko Job  ->  Registry (HTTPS)  ->  Deployment
```

1. **Dockerfile** stored in a ConfigMap (declarative, no external files)
2. **kaniko Job** reads the ConfigMap, builds the image, pushes to `registry.registry.svc.cluster.local:5000` with a version tag (`v1`, `v2`, ...)
3. **Deployment** pulls the pre-built image — no runtime apt installs

## Components

| File | Purpose |
|------|---------|
| `namespace.yml` | `registry` namespace |
| `registry.yml` | Deployment, Service, cert-manager Certificate |
| `registry-cleanup.yaml` | Daily CronJob that prunes old tags and runs garbage collection |
| `kustomization.yaml` | Kustomize grouping |
| `pv/` | PersistentVolume + PersistentVolumeClaim (10Gi on `/mnt/ssd/na/registry/data`) |
| `example/` | Reusable template showing the full build pattern |

## TLS

The registry serves HTTPS on port 5000. The cert-manager `Certificate` in `registry.yml` requests a cert for `registry.registry.svc.cluster.local` from the `la1r` ClusterIssuer. The resulting `registry-tls` Secret is mounted into the registry pod.

## Using the registry

### 1. Create a Dockerfile ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-dockerfile
data:
  Dockerfile: |
    FROM alpine:latest
    RUN apk add --no-cache curl
```

### 2. Create a build Job

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: myapp-build-image
spec:
  backoffLimit: 0
  template:
    spec:
      restartPolicy: Never
      containers:
      - name: kaniko
        image: gcr.io/kaniko-project/executor:latest
        args:
        - --dockerfile=Dockerfile
        - --context=/workspace
        - --destination=registry.registry.svc.cluster.local:5000/myapp:v1
        - --skip-tls-verify-registry=registry.registry.svc.cluster.local:5000
        - --cache=true
        - --single-snapshot
        volumeMounts:
        - name: dockerfile
          mountPath: /workspace/Dockerfile
          subPath: Dockerfile
      volumes:
      - name: dockerfile
        configMap:
          name: myapp-dockerfile
```

`--skip-tls-verify-registry` is used because kaniko runs inside the cluster — traffic to the ClusterIP never leaves the private network. Containerd on the node verifies TLS properly when pulling.

### 3. Reference the image in a Deployment

```yaml
containers:
- name: myapp
  image: registry.registry.svc.cluster.local:5000/myapp:v1
  imagePullPolicy: IfNotPresent
```

### Tag pattern

Images use incrementing version tags (`v1`, `v2`, `v3`...) instead of `:latest`. To rebuild an image:

1. Bump the version in both `container-build.yml` and the deployment YAML
2. Run `kubectl apply -k .` from the app directory

The build job creates the new image in the registry. The deployment's `IfNotPresent` automatically pulls the new tag since it doesn't exist on the node yet.

## Cleanup

`registry-cleanup.yaml` deploys a daily CronJob (`0 3 * * *`) that prunes old image tags and garbage-collects:

1. Lists every repo in the registry (regctl connects over the HTTPS endpoint via `regctl registry set --tls insecure`)
2. For each repo, keeps only the **newest tag by image `created` timestamp** and deletes the rest
3. Runs `registry garbage-collect --delete-untagged=true` to reclaim untagged blobs

Notes:

- A tag referenced by a running workload survives only if it is the newest-created in its repo. Bump to a new tag on release so the previous tag becomes pruneable.
- The job's Role grants `get` on `deployments` (namespace `registry`) so it can `kubectl exec` the registry Deployment for GC.
- regctl is pinned to `v0.11.5`. regctl has never supported a standalone `--insecure` flag — use `regctl registry set <host> --tls insecure` to skip cert verification.

## Rebuilding

```bash
kubectl delete job myapp-build-image
kubectl apply -f myapp-build-job.yml
```

## See also

- `example/` — complete template (Dockerfile ConfigMap + build Job + Deployment)
- `../development/ubuntu/` — real implementation replacing init containers
