#!/bin/bash
ansible-playbook -i inventory/hosts.yml site.yml

# Run specific roles using tags:
# ansible-playbook -i inventory/hosts.yml site.yml --tags "nfs,haproxy"

# To run on specific hosts:
# ansible-playbook -i inventory/hosts.yml site.yml --limit "linux-wayne"