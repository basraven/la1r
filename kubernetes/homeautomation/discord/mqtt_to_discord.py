import paho.mqtt.client as mqtt
import requests
import json
import time
import os
from io import BytesIO
import re
import threading
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')



MQTT_BROKER = "mqtt"
MQTT_PORT = 1883
MQTT_TOPIC_DETECTION = "frigate/+/person"
MQTT_TOPIC_SNAPSHOT = "frigate/+/person/snapshot"
MQTT_TOPIC_EVENTS = "frigate/events"
MQTT_TOPIC_REVIEWS = "frigate/reviews"

# Fetch Discord Webhook URL from environment variables
DISCORD_WEBHOOK_URL = os.getenv("FRIGATE_DISCORD_WEBHOOK")

# Global variables
eventState = {}
eventStateLock = threading.Lock()  # Create a global lock for thread safety

# Dictionary to store the last sent message time for each topic
last_sent_time = {}
# Cooldown period in seconds
COOLDOWN_PERIOD = 10


# Tool functions

def mqtt_topic_matches(pattern, topic):
    # Convert MQTT wildcard pattern to regex pattern
    pattern = pattern.replace('+', '[^/]+').replace('#', '.*')
    regex = f"^{pattern}$"
    return re.match(regex, topic) is not None

def get_decimal_color(score):
    # Ensure the score is within the range [0, 1]
    if score < 0 or score > 1:
        raise ValueError("Score must be between 0 and 1")

    # Apply a non-linear transformation to the score to adjust scaling
    if score <= 0.5:
        # Linear scaling for the first half
        transformed_score = 2 * score
    else:
        # Apply a power function to make the scaling more dramatic in the second half
        transformed_score = 1 - (1 - (2 * (score - 0.5)))**2

    # Calculate the RGB values
    red = int(255 * transformed_score)
    green = int(255 * (1 - transformed_score))
    blue = 0  # Keep the blue component zero for shades between red and green

    # Convert RGB to a single decimal color
    # The color format is: 0xRRGGBB
    decimal_color = (red << 16) + (green << 8) + blue

    return decimal_color

# App logic functions
def on_connect(client, userdata, flags, rc):
    logging.debug(f"Connected with result code {rc}")
    # client.subscribe(MQTT_TOPIC_DETECTION)
    client.subscribe(MQTT_TOPIC_SNAPSHOT)
    client.subscribe(MQTT_TOPIC_EVENTS)
    # client.subscribe(MQTT_TOPIC_REVIEWS)

def on_message(client, userdata, msg):
    global last_sent_time
    logging.info(f"#> Received message on topic {msg.topic}")

    current_time = time.time()
    # Check if the topic has been sent recently
    if msg.topic in last_sent_time:
        time_since_last_msg = current_time - last_sent_time[msg.topic]
        if time_since_last_msg < COOLDOWN_PERIOD:
            # logging.debug(f"Cooldown in effect for topic: {msg.topic}. Please wait {COOLDOWN_PERIOD - time_since_last_msg:.1f} more seconds.")
            return

    pair_event_with_snapshot(msg)

def pair_event_with_snapshot(msg):
    global eventState  # Use global to modify the global eventState variable
    
    with eventStateLock: # Acquire the lock before accessing eventState
        if mqtt_topic_matches(MQTT_TOPIC_SNAPSHOT, msg.topic):
            if eventState:
                send_to_discord(msg)
                eventState = {}  # Clear the eventState after processing
            # else:
                # logging.debug("Skipping snapshot because event was not created yet")

        elif mqtt_topic_matches(MQTT_TOPIC_EVENTS, msg.topic):
            event = json.loads(msg.payload)
            if event['after']['false_positive'] == False:
                # logging.debug("Event received, storing in eventState")
                eventState = msg.payload # Update eventState with the new event

def send_to_discord(msg):
    global last_sent_time
    event = json.loads(eventState)
    if mqtt_topic_matches(MQTT_TOPIC_SNAPSHOT, msg.topic):
        # logging.debug(f"Received payload size: {len(msg.payload)} bytes")
        image_stream = BytesIO(msg.payload)
        files = {
            'file': ('image.jpeg', image_stream, 'image/jpeg')
        }

        decimal_color = get_decimal_color(event['after']['score'])
        message_data = {
            "content": "Motion was detected in "+ event['after']['camera'] + " with score " + str(event['after']['score'] * 100 ) + "% confidence",
            "embeds": [
                {
                    "title": "Person detected at " + event['after']['camera'] ,
                    "description": "A person was detected.",
                    "image": {
                        "url": "attachment://image.jpeg"
                    },
                    "color": decimal_color
                }
            ]
        }

        # Convert the message data to a JSON string
        json_data = json.dumps(message_data)


        # Send the POST request with the image
        response = requests.post(DISCORD_WEBHOOK_URL, data={"payload_json": json_data}, files=files)
        last_sent_time[msg.topic] = time.time()
    # elif mqtt_topic_matches(MQTT_TOPIC_DETECTION, msg.topic):
    #     headers = {
    #     "Content-Type": "application/json"
    #     }
    #     data = {
    #         "content": msg.payload
    #     }
    #     response = requests.post(DISCORD_WEBHOOK_URL, data=json.dumps(data), headers=headers)
    else:
        logging.error("Unsuspected data received from Mqtt")
    
    if response.status_code == 204 or response.status_code == 200:
        logging.debug("Message sent to Discord successfully.")
    else:
        logging.debug(f"Failed to send message to Discord: {response.status_code}")

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
        time.sleep(1)  # Sleep for 1 second
except KeyboardInterrupt:
    logging.error("Script interrupted")
finally:
    client.loop_stop()  # Stop the loop when done