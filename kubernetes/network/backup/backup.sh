#!/bin/sh
echo "testen..."
# rsync -r --no-perms --no-owner --no-group --delete --force --update --progress -e "ssh -i /backup-ssh-key/id_rsa backup@10.8.0.18" /backup-ssh-key /tmp
mkdir -p ~/.ssh
cp /backup-ssh-key/id_rsa ~/.ssh/id_rsa
ssh backup@raspi2 'ls /'
