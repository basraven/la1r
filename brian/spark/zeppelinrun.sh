#!/bin/bash
docker build . -t zep
docker run -it -p 8088:80  -v /home/basraven/.kube/config:/root/.kube/config --rm zep bash 
