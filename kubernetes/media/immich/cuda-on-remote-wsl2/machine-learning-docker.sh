#!/bin/bash
docker run -it --rm --runtime=nvidia --gpus all -p 3003:3003 -v $(mktemp -d):/cache ghcr.io/immich-app/immich-machine-learning:main-cuda 