---
name: qbittorrent-vpn-ca-expiry
description: qBittorrent CrashLoopBackOff = expired GOOSE VPN CA in ovpn files of goose-credentials secret; fixed by refreshing secret AND rewriting bare auth-user-pass to point at /goose/login.conf
metadata:
  type: project
---

qbittorrent-standard (namespace `torrent`) pod CrashLoopBackOff (was 1384+ restarts). Two distinct root causes seen, both surface as "tun0 never up → probe kills container":

1. **Expired GOOSE provider CA** (incident 2026-09-04): inline `<ca>` in `.ovpn` files in `goose-credentials` Secret expired 2026-09-04. OpenVPN `VERIFY ERROR: ... CN=GOOSE CA` → tun0 never comes up. Rotation across ovpn keys does NOT help (all share the same CA).
2. **Bare `auth-user-pass`** (new portal configs 2026-09-08): fresh GooseVPN portal `.ovpn` files have `auth-user-pass` with NO file path. The `dyonr/qbittorrentvpn` image only injects `auth-user-pass credentials.conf` when BOTH `VPN_USERNAME` and `VPN_PASSWORD` env vars are set (this deployment sets neither). Result: OpenVPN tries interactive prompt, no tty → fatal `can't ask for 'Enter Auth Username:'`.

**Fix that worked:** Secret is the ONLY lever (deployment env/manifests are not changed for this). Rebuild `goose-credentials` from staged gitignored files in `kubernetes/torrent/qbittorrent/ovpn/` — but FIRST rewrite bare `auth-user-pass` → `auth-user-pass /goose/login.conf` in each staged `.ovpn` (the deployment mounts `login.conf` from the Secret at `/goose/login.conf`). Then run helper + rollout restart.

**Why:** Config-cycler initContainer copies the chosen `.ovpn` from Secret to PVC `/config/openvpn`; qbitvpn runs `openvpn --config <file>` as-is. Old (pre-2026) configs baked in the `/goose/login.conf` path; portal configs no longer do.

**How to apply:** Secret now holds `login.conf`, `ovpn1.ovpn` (pl-2), `ovpn2.ovpn` (hu-2) — old ovpn3-5 pruned by helper's apply semantics. Symptom check for auth issue: `kubectl logs <pod> -c qbitvpn | grep "Enter Auth Username"`. Helper `create-ovpn-secret.sh` is NOT executable — run `bash ./create-ovpn-secret.sh`. Verification: pod 1/1, `ip -o -4 addr show dev tun0`, endpoints populated, `curl -ksI https://torrent.bas` → 200. Related: [[traefik-api-group]]
