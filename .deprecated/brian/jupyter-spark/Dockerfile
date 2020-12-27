FROM ubuntu:latest

ENV SPARK_VERSION=2.4.5
ENV HADOOP_VERSION=2.7
ENV SPARK_HOME=/opt/spark
ENV PATH=$PATH:$SPARK_HOME/bin:$SPARK_HOME/sbin

# RUN add-apt-repository ppa:jonathonf/python-3.6
RUN apt-get update ; apt-get install -y curl default-jdk xz-utils python3
RUN curl -O "https://www-eu.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" ; tar xf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz ; mv spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}/ /opt/spark 
RUN pip3 install pyspark

ENV SPARK_MASTER_PORT 7077
ENV SPARK_MASTER_WEBUI_PORT 8080
ENV SPARK_MASTER_LOG /spark/logs

EXPOSE 8080 7077 6066

CMD ["/bin/bash", "spark-class", "org.apache.spark.deploy.master.Master", "--port", "7077", "--webui-port", "8080"]