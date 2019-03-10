#!/bin/sh
echo "Starting rsync file sync..."
rsync -a --no-perms --no-owner --no-group --delete --force --update --progress /nextcloud-web /backup/nextcloud/monthly
rsync -a --no-perms --no-owner --no-group --delete --force --update --progress /nextcloud-data /backup/nextcloud/monthly
