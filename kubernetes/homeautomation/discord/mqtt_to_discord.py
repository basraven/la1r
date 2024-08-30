import paho.mqtt.client as mqtt
import requests
import json
import os
from io import BytesIO
import re

MQTT_BROKER = "mqtt"
MQTT_PORT = 1883
MQTT_TOPIC_DETECTION = "frigate/+/person"
MQTT_TOPIC_SNAPSHOT = "frigate/+/person/snapshot"
MQTT_TOPIC_EVENTS = "frigate/events"
MQTT_TOPIC_REVIEWS = "frigate/reviews"

# Fetch Discord Webhook URL from environment variables
DISCORD_WEBHOOK_URL = os.getenv("DISCORD_WEBHOOK")



def mqtt_topic_matches(pattern, topic):
    # Convert MQTT wildcard pattern to regex pattern
    pattern = pattern.replace('+', '[^/]+').replace('#', '.*')
    regex = f"^{pattern}$"
    return re.match(regex, topic) is not None

def on_connect(client, userdata, flags, rc):
    print(f"Connected with result code {rc}")
    # client.subscribe(MQTT_TOPIC_DETECTION)
    client.subscribe(MQTT_TOPIC_SNAPSHOT)
    # client.subscribe(MQTT_TOPIC_EVENTS)
    # client.subscribe(MQTT_TOPIC_REVIEWS)

def on_message(client, userdata, msg):
    # print(f"Received message on topic {msg.topic}: {msg.payload.decode()}")
    print(f"Received message on topic {msg.topic}")
    
    
    # jpeg_image = msg.payload
    # # Create a file name (you can customize it based on your needs)
    # file_name = os.path.join(SAVE_PATH, f"{msg.topic.split('/')[-1]}.jpg")   
    # # Save the JPEG image to the specified path
    # with open(file_name, "wb") as f:
    #     f.write(jpeg_image)
    # print(f"Image saved to {file_name}")

    send_to_discord(msg)

def send_to_discord(msg):
    if mqtt_topic_matches(MQTT_TOPIC_SNAPSHOT, msg.topic):
        print(f"Received payload size: {len(msg.payload)} bytes")
        # Use BytesIO to create an in-memory binary stream
        image_stream = BytesIO(msg.payload)
        # Prepare the files parameter for the request
        files = {
            'file': ('image.jpg', image_stream, 'image/jpeg')
        }
        # Send the POST request with the image
        response = requests.post(DISCORD_WEBHOOK_URL, files=files)
    # elif mqtt_topic_matches(MQTT_TOPIC_EVENTS, msg.topic) or mqtt_topic_matches(MQTT_TOPIC_REVIEWS, msg.topic) :
    #     print(msg.payload)
    elif mqtt_topic_matches(MQTT_TOPIC_DETECTION, msg.topic):
        headers = {
        "Content-Type": "application/json"
        }
        data = {
            "content": msg.payload
        }
        response = requests.post(DISCORD_WEBHOOK_URL, data=json.dumps(data), headers=headers)
    
    
    if response.status_code == 204:
        print("Message sent to Discord successfully.")
    else:
        print(f"Failed to send message to Discord: {response.status_code}")

# Updated client initialization
# client = mqtt.Client(protocol=mqtt.MQTTv5)  # or mqtt.MQTTv311 if v5 is not supported
client = mqtt.Client() # Use default MQTT version

client.on_connect = on_connect
client.on_message = on_message

client.connect(MQTT_BROKER, MQTT_PORT, 60)
client.loop_start()  # Use loop_start() for non-blocking behavior

# Keep the script running
try:
    while True:
        pass
except KeyboardInterrupt:
    print("Script interrupted")
finally:
    client.loop_stop()  # Stop the loop when done