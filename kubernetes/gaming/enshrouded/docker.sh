#!/bin/bash

docker volume create enshrouded-persistent-data
docker run \
  --detach \
  --name enshrouded-server \
  --mount type=volume,source=enshrouded-persistent-data,target=/home/steam/enshrouded/savegame \
  --publish 15637:15637/udp \
  --publish 27015:27015/udp \
  --env=SERVER_NAME='Enshrouded Containerized Server' \
  --env=SERVER_SLOTS=16 \
  --env=SERVER_PASSWORD='ChangeThisPlease' \
  --env=PORT=15637 \
  sknnr/enshrouded-dedicated-server:latest