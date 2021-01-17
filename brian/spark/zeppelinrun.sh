#!/bin/bash
SPARK_VERSION=3.0.1
docker build . -t docker.io/basraven/zeppelin:$SPARK_VERSION
docker run -it -p 8088:80  -v /home/basraven/.kube/config:/root/.kube/config --rm docker.io/basraven/zeppelin:$SPARK_VERSION bash 
