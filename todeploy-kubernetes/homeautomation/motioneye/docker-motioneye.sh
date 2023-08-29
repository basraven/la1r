#!/bin/bash
# apt-get install docker-ce docker-ce-cli
CONFIGDIR=/mnt/hdd/na/homeautomation-motioneye-config-claim-pvc-45fd8752-92e3-47e0-92fe-99c576791b2a
CAMERADIR=/mnt/hdd/na/cameras-lowpower
mkdir -p $CAMERADIR

# DEV
#CONFIGDIR=/mnt/d/Bas/Documents/Projects/la1r/motioneye-config
#CAMERADIR=/mnt/d/Bas/Documents/Projects/la1r/cameras-lowpower

docker run -d --rm -e TZ='Europe/Amsterdam' -e PGID='1000' -e PUID='1000' -v $CONFIGDIR:/etc/motioneye -v $CAMERADIR:/var/lib/motioneye -p 8765:8765 ccrisan/motioneye:master-amd64