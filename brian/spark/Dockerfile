FROM apache/zeppelin:0.9.0
ENV SPARK_VERSION=3.0.1
RUN wget https://mirror.lyrahosting.com/apache/spark/spark-$SPARK_VERSION/spark-$SPARK_VERSION-bin-hadoop3.2.tgz && tar -zvxf ./spark-$SPARK_VERSION-bin-hadoop3.2.tgz && mv  ./spark-$SPARK_VERSION-bin-hadoop3.2 ./spark3  && rm -rf ./spark-$SPARK_VERSION-bin-hadoop3.2.tgz  
USER root