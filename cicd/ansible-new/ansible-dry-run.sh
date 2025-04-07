#!/bin/bash
ansible-playbook -i inventory/hosts.yml site.yml  --check

# Run specific roles using tags:
# ansible-playbook -i inventory/hosts.yml site.yml --tags "nfs,haproxy"  --check

# To run on specific hosts:
# ansible-playbook -i inventory/hosts.yml site.yml --limit "linux-wayne"  --check