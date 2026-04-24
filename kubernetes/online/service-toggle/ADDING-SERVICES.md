# Service Toggle

Web UI to start/stop (scale to 1/0) selected deployments in the cluster.

## Architecture

- A FastAPI app running as a Deployment in `namespace: online`
- Uses a `ServiceAccount` with RBAC `Role` + `RoleBinding` per managed service
- Managed services are configured via the `TOGGLE_DEPLOYMENTS` environment variable
- The UI is served at `https://toggle.bas`

## Adding a New Service

Provide these details:

- **Deployment name** (e.g. `enshrouded`)
- **Namespace** (e.g. `gaming`)

### What gets created

For each new service, add three things to `service-toggle.yml`:

1. **Role** — grants `get` and `patch` on `deployments/scale` for that specific deployment in its namespace.
2. **RoleBinding** — binds that Role to the `service-toggle` ServiceAccount in `namespace: online`.
3. **TOGGLE_DEPLOYMENTS entry** — adds a JSON entry to the array in the Deployment's env var.

   **Simple mode** (default on/off toggle):
   ```json
   {"name":"<deployment>","namespace":"<namespace>"}
   ```

   **Timed mode** (start with +1h/+2h/+4h options, auto scale-down):
   ```json
   {"name":"<deployment>","namespace":"<namespace>","mode":"timed","options":[1,2,4]}
   ```
   - `mode`: `"simple"` (default) or `"timed"`
   - `options`: list of hour values to show as buttons (default `[1,2,4]`)
   - In timed mode, the backend auto-scales the deployment to 0 when the timer expires

Then run `kubectl apply -k kubernetes/online/service-toggle/` to deploy.

### Example

For `enshrouded` in `gaming`:

```yaml
# Role in the target namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: service-toggle
  namespace: gaming
rules:
- apiGroups: ["apps"]
  resources: ["deployments/scale"]
  resourceNames: ["enshrouded"]
  verbs: ["get", "patch"]
---
# RoleBinding in the target namespace
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: service-toggle
  namespace: gaming
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: service-toggle
subjects:
- kind: ServiceAccount
  name: service-toggle
  namespace: online
```

```yaml
# Env var entry in the Deployment spec
- name: TOGGLE_DEPLOYMENTS
  value: '[{"name":"enshrouded","namespace":"gaming"},{"name":"system-audit","namespace":"monitoring"}]'
```

### Important notes

- Each service needs its **own Role+RoleBinding pair**. Roles are namespaced, so a service in `gaming` needs a Role in `gaming`, a service in `monitoring` needs a Role in `monitoring`, etc.
- The `resourceNames` field on the Role restricts permission to **only that specific deployment** — the toggle can't accidentally scale other deployments in the same namespace.
- Roles are all named `service-toggle` (same name in every namespace). RoleBindings are all named `service-toggle` too. This is intentional — `kubectl` won't complain about duplicate names because they live in different namespaces.
- The Deployment itself is **not** modified — only the `scale` subresource is read/patched. The app stays running at whatever replica count it was at before toggle was enabled.
