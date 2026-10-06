# authentik

SSO / identity provider for the homelab (OIDC + forward-auth via the embedded
outpost). All apps use authentik forward-auth middlewares through Traefik.

Current version: **2026.8.3** (`ghcr.io/goauthentik/server:2026.8.3`, server +
worker). Upgraded sequentially through every intermediate minor: 2025.8.4 →
2025.8.6 → 2025.10.4 → 2025.12.6 → 2026.2.7 → 2026.5.7 → 2026.8.3 (no skipped
versions; each hop was verified and the DB dumped as rollback).

## Key configuration in `authentik.yml`
- **`strategy: Recreate`** on postgres/server/worker — a single-replica auth
  service must never run two versions at once during a migration.
- **Redis removed** (since 2025.10): no `AUTHENTIK_REDIS__*` env, no redis
  Deployment/Service; cache, tasks, embedded outpost and websockets are
  Postgres-backed (~50% more DB connections, max_connections=100).
- **Storage layout** (since 2025.12): the filesystem-backed media is expected
  under `/data/media/<schema>`. The PVC is mounted at `/data`; during the upgrade
  the existing `/media/public/...` content was moved to `media/public/...` inside
  the PVC, so `/data/media/public/...` is where application icons/flow backdrops
  live and the Files library reports `manageable: true`.
- **`AUTHENTIK_WEB__BASE_URL=https://auth.la1r.com`** (recommended now, required
  in 2026.11).
- Postgres stays on **16**.

## Secrets
All sensitive values are referenced by name from the **`authentik-secrets`**
Secret (e.g. `AUTHENTIK_SECRET_KEY`, `POSTGRES_PASSWORD`,
`AUTHENTIK_BOOTSTRAP_*`). None are committed; recreate the Secret out-of-band on
a rebuild. `AUTHENTIK_AVATAR`, log-level and other non-secret settings live in
the manifest.

## Access / flows
- Login: `https://auth.la1r.com` (root `302`s to the default authentication flow).
- Forward-auth endpoint used by Traefik middlewares:
  `http://authentik.security.svc.cluster.local:9000/outpost.goauthentik.io/auth/traefik`.

## Apply
```
kubectl apply -k kubernetes/security/authentik/
```

## Notes
- Post-upgrade `ANALYZE;` was run on the database (recommended after the 2025.12
  RBAC/storage migrations).
- `User.ak_groups` deprecation warnings in the server log come from authentik's
  built-in "OpenID 'profile'" mapping and will disappear in a future release.