#!/bin/bash

# Should be replaced by systemd service
# zfs load-key emergency-onsite
# zfs mount emergency-onsite

LOG_FILE="emergency-backup.log"
rm emergency-backup.log 

# Sync for local backup
mkdir -p /mnt/emergency-onsite/jay-c
echo "Syncing local backup at $(date)" | tee -a "$LOG_FILE"
rsync -av /mnt/hdd/media/ /mnt/emergency-onsite/jay-c/hdd/media/  | tee -a "$LOG_FILE"
rsync -av /mnt/hdd/ha/ /mnt/emergency-onsite/jay-c/hdd/ha/  | tee -a "$LOG_FILE"
rsync -av /mnt/hdd/na/ /mnt/emergency-onsite/jay-c/hdd/na/  | tee -a "$LOG_FILE"
echo "Done Syncing local backup at $(date)" | tee -a "$LOG_FILE"


# Sync for linux-wayne backup
# REMOTE_HOST="basraven@192.168.5.1"
# mkdir -p /mnt/emergency-onsite/linux-wayne
# rsync -av -e "ssh" --rsync-path="sudo rsync" "$REMOTE_HOST:/mnt/ssd/ha" /mnt/emergency-onsite/linux-wayne/ha | tee -a "$LOG_FILE"
# rsync -av -e "ssh" --rsync-path="sudo rsync" "$REMOTE_HOST:/mnt/ssd/na" /mnt/emergency-onsite/linux-wayne/na | tee -a "$LOG_FILE"
# shutdown now