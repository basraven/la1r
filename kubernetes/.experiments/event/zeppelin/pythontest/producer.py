#!/usr/bin/python3
from time import sleep
from json import dumps
from kafka import KafkaProducer

producer = KafkaProducer(bootstrap_servers=["kafka.event.svc.cluster.local:9092"], value_serializer=lambda x: dumps(x).encode("utf-8"))
                         
for e in range(1000000000):
    data = {"number" : e}
    producer.send("test", value=data)
    sleep(0.5)