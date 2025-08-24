# Ansible Automation (Modernized)

This directory contains the modernized Ansible automation setup for la1r infrastructure, including inventory, roles, and orchestration scripts.

## Structure
- **ansible.sh**: Main entrypoint script to run Ansible playbooks with environment setup.
- **ansible-dry-run.sh**: Script for running playbooks in dry-run (check) mode.
- **site.yml**: The main playbook, orchestrating all roles and tasks for the infrastructure.
- **inventory/**: Contains inventory files and host/group variables for all managed environments.
- **roles/**: Contains reusable Ansible roles for provisioning, configuration, and app deployments.

## Usage
- Use `ansible.sh` to execute the main playbook (`site.yml`) against the inventory.
- Use `ansible-dry-run.sh` to preview changes without making modifications.
- Place host and group variables in the appropriate directories under `inventory/`.
- Add or update roles as needed in the `roles/` directory.

## References
- [Ansible Documentation](https://docs.ansible.com/)
