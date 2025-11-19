# Borg Backup

This directory contains manifests for the remote-cube backup and uses Borg backup to do this

## Structure


## Usage


1. First you need borg to create a key, never let ssl or other tools do this
```bash
sudo borg init --encryption=keyfile-blake2 /mnt/hdd/backup/jay-c/ssd/na.borg

# Get the repo private key
sudo borg key export /mnt/hdd/backup/jay-c/ssd/na.borg /tmp/borg-repo-key
sudo cat /tmp/borg-repo-key | base64 -w0
# Copy the output above and store it in a secret

# Get the repo ID for the backup job (to be used as target file name)
REPOID=$(sudo borg info /mnt/hdd/backup/jay-c/ssd/na.borg | awk -F': ' '/Repository ID/ {print $2}')


```



