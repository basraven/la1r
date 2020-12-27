#!/usr/bin/python3
from kafka import KafkaConsumer
from json import loads

consumer = KafkaConsumer(
    "test10",
     bootstrap_servers=["kafka.event.svc.cluster.local:9092"],
    auto_offset_reset="earliest",
    consumer_timeout_ms=1000
    )

for message in consumer:
    print(message.value)