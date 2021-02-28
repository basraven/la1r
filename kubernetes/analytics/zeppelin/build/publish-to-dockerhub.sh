#!/bin/bash
SPARK_VERSION=3.0.1
ZEPPELIN_VERSION=0.9.1

# Execute from spark brain folder
docker build . -t docker.io/basraven/zeppelin:$ZEPPELIN_VERSION
docker push docker.io/basraven/zeppelin:$ZEPPELIN_VERSION


# Execute from SPARK_HOME (Downloaded tar)
./bin/docker-image-tool.sh -r docker.io/basraven -t $SPARK_VERSION -p kubernetes/dockerfiles/spark/bindings/python/Dockerfile build 
docker tag basraven/zep-spark/spark:$SPARK_VERSION docker.io/basraven/spark:$SPARK_VERSION
docker tag basraven/zep-spark/spark-py:$SPARK_VERSION docker.io/basraven/spark-py:$SPARK_VERSION
docker push docker.io/basraven/spark:$SPARK_VERSION
docker push docker.io/basraven/spark-py:$SPARK_VERSION
