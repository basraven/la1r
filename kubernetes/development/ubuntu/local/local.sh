#!/bin/bash

# Stop and remove existing container if it exists
docker stop ubuntu-xfce4-gui || true
docker rm ubuntu-xfce4-gui || true

# Build your new lightweight image
docker build -t ubuntu-xfce4-gui .

# Run the container
docker run -d \
  --name xfce4-container \
  -p 6080:6080 \
  -p 5900:5900 \
  -v /dev/shm:/dev/shm \
  ubuntu-xfce4-gui