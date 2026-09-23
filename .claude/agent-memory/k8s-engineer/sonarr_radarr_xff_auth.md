---
name: sonarr-radarr-xff-auth
description: sonarr.bas/radarr.bas suddenly demand login — arr apps enforce auth for any X-Forwarded-For request unless TrustedNetworks lists the proxy; fix lives in PVC config, not git
metadata:
  type: project
---

`sonarr.bas` / `radarr.bas` (namespace `torrent`) enforce their own login whenever the
request arrives via Traefik, because Traefik adds `X-Forwarded-For` and the apps'
`TrustedNetworks` was empty (no trusted reverse proxy configured). Symptom appeared
2026-09-23 after the 2026-09-19 image upgrade (sonarr 4.0.19.2979 -> 4.0.20.3014,
radarr 6.1.1 -> 6.3.0 -> 6.4.4.10685) pulled by `imagePullPolicy: Always` on the
unpinned `linuxserver/sonarr` / `linuxserver/radarr` tags in
`kubernetes/torrent/{sonarr,radarr}/*.yml`. Newer builds no longer treat a forwarded
request from an untrusted proxy as local (CVE-2026-30975 hardening).

**Why:** the deployed manifests and the PVC-stored `config.xml` were both unchanged
(verified against `/config/Backups/scheduled/*.zip` from 2026-09-21), so the trigger was
the image bump, not a config regression — easy to misdiagnose as a lost hostPath/PV.

**How to apply:** if either app asks for a password (sonarr = Basic 401, radarr = 302 to
`http://<host>/login` which 404s because the ingress has no `web` entrypoint router),
check `TrustedNetworks` in the app config. The working fix applied 2026-09-23 was
`TrustedNetworks = 10.244.0.0/16` (pod CIDR, so it survives Traefik pod IP changes).
Note this setting lives ONLY in the PVC `config.xml` (via Settings -> General or
`PUT /api/v3/config/host`) — it is NOT in git, so it would be lost on a config reset.
Controlled repro: direct pod->pod request gets 200 (no auth); the same request plus only
`X-Forwarded-For` gets auth; `X-Forwarded-Proto`/`Host`/`X-Real-Ip` alone do not.
See [[kubeconfig-la1r-path]] and [[qbittorrent_vpn_ca_expiry]].
