#!/bin/bash
ansible-playbook -i hosts.yml  stephanie.yml
# ansible-playbook -i hosts.yml  --ask-pass --ask-become-pass stephanie.yml
