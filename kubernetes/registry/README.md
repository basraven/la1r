# Internal OCI Container Registry

In-cluster container registry replacing init-container apt installs at pod startup. Images are built via kaniko Jobs and pushed to this registry over HTTPS (TLS via cert-manager).

## How it works

```
ConfigMap (Dockerfile)  ->  kaniko Job  ->  Registry (HTTPS)  ->  Deployment
```

1. **Dockerfile** stored in a ConfigMap (declarative, no external files)
2. **kaniko Job** reads the ConfigMap, builds the image, pushes to `registry.registry.svc.cluster.local:5000`
3. **Deployment** pulls the pre-built image — no runtime apt installs

## Components

| File | Purpose |
|------|---------|
| `namespace.yml` | `registry` namespace |
| `registry.yml` | Deployment, Service, cert-manager Certificate |
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
        - --destination=registry.registry.svc.cluster.local:5000/myapp:latest
        - --skip-tls-verify-registry=registry.registry.svc.cluster.local:5000
        - --cache=false
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
  image: registry.registry.svc.cluster.local:5000/myapp:latest
```

### Rebuilding

```bash
kubectl delete job myapp-build-image
kubectl apply -f myapp-build-job.yml
```

## See also

- `example/` — complete template (Dockerfile ConfigMap + build Job + Deployment)
- `../development/ubuntu/` — real implementation replacing init containers
