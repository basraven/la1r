---
name: Workflow backup template structure
description: Pattern used for Argo workflow backup templates across the repo
type: project
---

The repo uses Argo WorkflowTemplates and CronWorkflows for backup jobs, organized under `kubernetes/workflows/templates/`.

Each backup group (essential-cloud-backups, nonessential-cloud-backups, glacier-cloud-backups) follows the same kustomize structure:
- `kustomization.yaml` referencing `pv/`, a workflow YAML, and `crons/` subdirectories
- PV/PVC pairs in `pv/` for data volumes and working directories
- WorkflowTemplate with templates: `essential-cloud-backup` (DAG entrypoint), `encrypt-backup`, `upload-backup`, `clean-workingdir`, `exit-handler`, `notify`
- CronWorkflow in `crons/` referencing the shared template

**Why:** Standardized pattern ensures all backups have consistent encrypt-upload-cleanup lifecycle with S3 glacier-compatible upload and ntfy notifications.

**How to apply:** New backup groups should follow this exact structure. Check existing `essential-cloud-backups` for the canonical pattern when reviewing new additions.
