---
name: seerr-v3-nonroot-image
description: seerr v3 image (renamed from jellyseerr) runs as uid/gid 1000 node:node and needs /app/config owned by 1000:1000; EACCES on /app/config/logs means root-owned files, fix with a root helper pod
metadata:
  type: project
---

The jellyseerr upstream project was renamed `fallenbagel/jellyseerr` -> `seerr-team/seerr`
(2026-09-23). Old image path `ghcr.io/fallenbagel/jellyseerr:latest` is frozen at 2.7.3;
new tags only exist at `ghcr.io/seerr-team/seerr` (e.g. `v3.4.1`).

**Verified image facts** (readable from the GHCR config blob without pulling — anonymous
token from `https://ghcr.io/token?scope=repository:<repo>:pull`, then the manifest, then the
config blob):

- v2.7.3: no `User` field -> ran as root, entrypoint `/sbin/tini --`.
- v3.4.1: `"User":"node:node"` = **uid/gid 1000**, WorkingDir `/app`, ExposedPort 5055/tcp,
  entrypoint `docker-entrypoint.sh`, Cmd `npm start`. The `PUID`/`PGID` env the Deployment
  sets are ignored by the v3 image (they were a linuxserver-ism) — harmless, but dead config.

**Failure mode:** v3.4.1 crash-loops at logger setup if /app/config is not writable by 1000:

    Error: EACCES: permission denied, open '/app/config/logs/seerr-<date>.log'
    (file-stream-rotator -> FileStreamRotator.js)

Note v3 renames its log files `jellyseerr-*.log` -> `seerr-*.log`, so the first thing it does
in `logs/` is *create* a new file. It prints `Starting Seerr version 3.4.1` before dying, so
that line is NOT proof of a healthy start — look for `Server ready on port 5055`.

**Fix:** chown the claim contents to 1000:1000 from a root helper pod:
`chown -R 1000:1000 /cfg` (mount `jellyseerr-config-claim` at `/cfg`, alpine, no
securityContext). The PV is hostPath `/mnt/ssd/na/jellyseerr-config` on jay-c and CAN be
chowned in place from a pod — no node/ssh access needed.

**Why:** the whole volume was owned by uid/gid 0 under v2.7.3 — that image ran as root, so
root ownership was the steady state, not residue from backup or helper-pod activity (the
before-chown listing showed `cache/`, `db/`, `settings.json`, `db/db.sqlite3`, `logs/` all
0:0 with mtimes from Apr 2025 onward). The recursive chown is therefore a **required
one-time migration step** for any root -> non-root image bump on a hostPath PV, not cleanup
of stray files: recreate the volume fresh and it comes up root-owned and breaks all over
again. Deleting/repointing the volume loses the config.

**How to apply:** on any seerr image bump, check the image config `User` before applying, and
if the pod dies with EACCES on /app/config, chown to 1000:1000 rather than making the
container root (`fsGroup` does NOT help — kubelet applies no ownership recursion to
hostPath volumes; initContainers are off-limits per repo agent rules).

**Diagnosis trap (cost me a wrong root-cause call on 2026-09-23):** if someone else has
already applied a fix while you were idle, your measurements are post-fix. Re-reading the
volume after the chown showed everything 1000:1000 and led me to "correct" a correct
diagnosis into a wrong one. Before revising a cause you already established, establish
whether the state you are measuring predates the fix — ask for or use the before-state, and
if you can't get it, say the cause is unverified rather than inverting it.

Successful v3.4.1 migration (2026-09-23) applied settings migrations `0007_migrate_arr_tags`
and `0008_migrate_blacklist_to_blocklist`, then `Server ready on port 5055`; `/api/v1/status`
returned version 3.4.1 on both the ClusterIP and the LoadBalancer 192.168.6.62:5055.

Related: [[kubeconfig-la1r-path]], [[sonarr_radarr_xff_auth]].
