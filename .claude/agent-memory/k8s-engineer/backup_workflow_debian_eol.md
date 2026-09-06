---
name: backup_workflow_debian_eol
description: Argo backup WorkflowTemplates apt-install gnupg at runtime on debian:trixie-slim; distro pin is EOL-sensitive (bullseye broke 2026-08-31)
metadata:
  type: project
---

The shared Argo WorkflowTemplates in ns `workflows` (`essential-cloud-backup`, `nonessential-cloud-backup`, `glacier-cloud-backup`) run `apt update && apt install -y gnupg` **at runtime** in an encrypt step on `debian:<distro>-slim` — no pre-baked image. When Debian reaches EOL the apt repos 404 and every backup fails at encrypt with exit 127 / `gpg: not found`.

**Why:** bullseye hit EOL 2026-08-31; the 2026-09-06 weekly run failed all 16 backups exactly that way. Fix was bumping the pin to `debian:trixie-slim` in the repo templates and `kubectl apply -k kubernetes/workflows/` (templates only; CronWorkflows were unchanged).

**How to apply:** When backups fail cluster-wide at the encrypt/apt step, first check the template image tag — bump the Debian pin before debugging anything else. The workflow templates live in `kubernetes/workflows/templates/{essential,nonessential,glacier}-cloud-backups/` and mount PVs that expose only the app source paths (app source folders are under `/mnt/ssd/{ha,na}/<app>`; a `nonessential` app can live under `ha/` and vice-versa — copy cron params verbatim, don't infer).

Template defaults: bucket + storageclass (`STANDARD_IA`) are global-param defaults on the template; CronWorkflows only pass `appname` + `localpath`. Essential bucket `la1r-backup-versioned-backup-data` path `ha/<app>/<app>.gpg`; nonessential bucket `la1r-backup-backup-data` path `na/<app>/<app>.gpg`.

`weekly-homeassistant-cloud-backup` CronWorkflow is **not** tracked in the repo workflows kustomization (applied out-of-band, still references `nonessential-cloud-backup` template) — include it manually when re-running failed backups. immich-db's `appname` param is `immich`.

Backup-uploader S3 creds live in secret `aws-config-backup-uploader` (ns workflows, items config+credentials). Local `~/.aws` creds are stale (`InvalidClientTokenId`); verify S3 via a throwaway `amazon/aws-cli` pod mounting that secret on jay-c.
