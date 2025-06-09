
#docker build -f ./kubernetes/dockerfiles/spark/Dockerfile . -t sparkworker 

    export SPARK_HOME=`pwd`


    $SPARK_HOME/bin/spark-submit \
  --master k8s://https://192.168.5.100:443 \
  --deploy-mode cluster \
  --name spark-pi \
  --class org.apache.spark.examples.SparkPi \
  --conf spark.executor.instances=5 \
  --conf spark.kubernetes.namespace=analytics \
  --conf spark.kubernetes.authenticate.driver.serviceAccountName=spark \
  --conf spark.kubernetes.container.image=newfrontdocker/spark-py:v3.0.1-j14 \
    local:///opt/spark/examples/jars/spark-examples_2.12-3.0.1.jar
