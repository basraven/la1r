# Pi-hole

DNS sinkhole + ad-blocker for the cluster and LAN, with external-dns
integration (auto-creates records for Services/Ingresses).

Current version: **Pi-hole v6** (image `pihole/pihole:2026.09.0` — upgraded from
v5 in 2026). v6 is a rewrite: single `pihole-FTL` binary with an embedded web
server + REST API, TOML config (`/etc/pihole/pihole.toml`), native HTTPS and
DoT/DoH-ready upstreams.

## Key changes since the v5 layout
- Image `2024.07.0` (v5) → `2026.09.0` (v6).
- Legacy v5 env vars (`WEBPASSWORD`, `VIRTUAL_HOST`, `WEB_PORT`,
  `DNS_FQDN_REQUIRED`, `DNS_BOGUS_PRIV`, `DNSMASQ_LISTENING`, `WEBTHEME`,
  `RATE_LIMIT`) replaced with v6 `FTLCONF_*` settings (see `pihole.yml`):
  `FTLCONF_webserver_api_password`, `FTLCONF_webserver_port`,
  `FTLCONF_webserver_interface_theme`, `FTLCONF_dns_listeningMode`,
  `FTLCONF_dns_upstreams`, `FTLCONF_dns_domainNeeded`,
  `FTLCONF_dns_bogusPriv`, `FTLCONF_misc_etc_dnsmasq_d`.
- The v5 `setupVars.conf` ConfigMap (unmounted, dead) was removed.
- On first v6 start the image migrates the existing `/etc/pihole` v5 data in
  place (`migration_backup_v6/`); existing local DNS records are preserved.

## Secrets
- The web/API password is read from the **`pihole-credentials`** Secret (key
  `API_PASSWORD`), referenced by name from `pihole.yml` and
  `pihole-external-dns.yml`. Create/refresh it out-of-band (do **not** commit
  the value):
  ```
  kubectl create secret generic pihole-credentials -n dns \
    --from-literal=API_PASSWORD="$(openssl rand -base64 24)"
  ```

## external-dns
- `pihole-external-dns.yml` runs external-dns **v0.22.0** against the Pi-hole
  v6 API (`--pihole-server=http://pihole:80`, provider adds `/api/...`),
  authenticating with `EXTERNAL_DNS_PIHOLE_PASSWORD` from the same Secret.

## Access
- Admin UI: `https://dns.bas/admin/` (behind authentik forward-auth).
- DNS for LAN: `192.168.6.91:53`.

## Apply
```
kubectl apply -k kubernetes/dns/pihole/
```

## See also
- `kubernetes/network-policies/` — the dns namespace is default-deny; DNS 53 is
  open to all, the web/API is restricted to the ingress controllers, monitoring
  and in-namespace consumers.