#!/bin/bash
# Renew kubeadm PKI certs on the control plane (jay-c). Backs up first,
# re-mints a long-lived admin client cert, restarts control-plane pods,
# and verifies. Self-skips if certs are still fresh unless renew_force=true.
#
#   ./renew-certs.sh                    # run now
#   ./renew-certs.sh -e renew_force=true
#   ./renew-certs.sh --check
set -euo pipefail
cd "$(dirname "$0")"
ansible-playbook -i hosts.yml renew-certs.yml --limit jay-c --private-key ~/.ssh-la1r/id_rsa "$@"
