# LiteLLM Gateway

LiteLLM proxy hosting LLM providers for the development namespace. It fronts **DeepInfra**
so clients (like `claudecodeui`) reach one OpenAI/Anthropic-compatible endpoint at
**`https://litellm.la1r.com`** instead of talking to providers directly.

## Structure
- **`litellm.yml`** — `Deployment -> Service -> Certificate -> Ingress` (single file):
  - Deployment `litellm` (image `ghcr.io/berriai/litellm:main-stable`, port 4000, arg
    `--config /app/config.yaml --port 4000`)
  - Service `litellm` → port 80 → 4000
  - Certificate `letsencrypt-litellm-la1r-com` (ClusterIssuer `letsencrypt-la1r`, Let's Encrypt via DNS-01)
  - Ingress `litellm-la1r-com-https` → host `litellm.la1r.com` (Traefik, websecure)
- **`config.yaml`** — LiteLLM router config (mounted as ConfigMap `litellm-config`)
- **`postgres.yml`** — dedicated PostgreSQL (in the `development` ns) backing litellm's
  virtual keys / spend tracking (LiteLLM requires PostgreSQL; SQLite is unsupported)
- **`pv/`** — hostPath PV + PVC for the Postgres data dir at `/mnt/ssd/ha/litellm`
- **`kustomization.yml`** — namespaced overlay; register new resources here

## Configuration

`config.yaml` maps a client-facing model name to a provider+model. Current route:

```yaml
model_list:
  - model_name: deepseek-v4-flash
    litellm_params:
      model: deepinfra/deepseek-ai/DeepSeek-V4-Flash-0731
      api_key: os.environ/DEEPINFRA_API_KEY
      extra_body:
        service_tier: flex
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
```

- **`LITELLM_MASTER_KEY`** — gateway/admin key; unlocks the admin UI at `/ui`.
- **`DEEPINFRA_API_KEY`** — upstream key used to call DeepInfra.
- Both injected via `valueFrom.secretKeyRef` from the Kubernetes Secret
  `litellm-master-key` (keys `LITELLM_MASTER_KEY` and `DEEPINFRA_API_KEY`).
- **`DATABASE_URL`** — PostgreSQL (deployment `litellm-postgres`, service
  `litellm-postgres:5432`), required for virtual keys; injected from Secret
  `litellm-postgres-credentials`.
- **Client auth uses a virtual key** (`sk-...`), created via `/ui` or `/key/generate` —
  not the master key. The master key is rejected by client endpoints in this build.

### Adding or changing a model
1. Edit `config.yaml` → add/change a `model_list` entry (provider prefix, e.g.
   `deepinfra/<model-id>`, `anthropic/<model>`, `openai/<model>`).
2. `kubectl apply -k kubernetes/development/litellm/` (ConfigMap + Deployment update).
3. The Deployment rolls automatically because the pod env/ConfigMap changed.

### Rotating / updating keys
The key values live **only** in the private `la1r-cred` repo at
`credentials/kubernetes/litellm-master-key.yml` (git-ignored plaintext, GPG `.asc`
encrypted for commit). Edit that file, then:

```sh
kubectl apply -f credentials/kubernetes/litellm-master-key.yml
kubectl -n development rollout restart deploy/litellm
```

Never put key values in this repo's manifests or commit messages.

## Usage

litellm serves the Anthropic-format API at the **root** `/v1/messages` path (Claude Code
appends `/v1/messages` to `ANTHROPIC_BASE_URL` automatically). Use the root URL — **not**
the `/anthropic` passthrough, whose key auth is unreliable in this build. Authenticate
with a **virtual key** (`sk-...`), not the master key.

In-cluster clients (same `development` namespace) use the Service DNS:

```
http://litellm                    # Anthropic-format (ANTHROPIC_BASE_URL)
http://litellm/v1                 # OpenAI-format
```

Fully-qualified: `http://litellm.development.svc.cluster.local:80`

External (via ingress):

```
https://litellm.la1r.com          # Anthropic-format (ANTHROPIC_BASE_URL)
https://litellm.la1r.com/v1       # OpenAI-format
```

### claudecodeui
Point `ANTHROPIC_BASE_URL` at `http://litellm` (root; Claude Code appends
`/v1/messages`), `ANTHROPIC_AUTH_TOKEN` to the **virtual key** (`sk-...`), and keep
`ANTHROPIC_MODEL: deepseek-v4-flash`.

## Health checks
- `GET https://litellm.la1r.com/health/liveliness` — unauthenticated
- `GET https://litellm.la1r.com/health/readiness` — requires master key
- `GET https://litellm.la1r.com/v1/models` — lists registered models (requires master key)
