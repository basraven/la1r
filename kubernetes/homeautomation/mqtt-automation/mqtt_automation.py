import paho.mqtt.client as mqtt
import json
import time
import ephem
from datetime import datetime, timedelta
import re
import os
import threading
import logging

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

MQTT_BROKER = "mqtt"
MQTT_PORT = 1883

# Define coordinates for Hilversum, Netherlands
latitude = '52.2319'
longitude = '5.1669'

# Global variables
lastAutomationTime = {}
lastAutomationTimeLock = threading.Lock()  # Create a global lock for thread safety
switchOffTimers = {}
backOffTimers = {}


TOPIC_SUBSCRIPTIONS = [
    "frigate/achtertuin/person",
    "hue2mqtt/group/13"
]

TIMEOUT_SWITCH_ON_RESET = 4 * 60 * 60  # 4 hours in seconds
TIMEOUT_SWITCH_OFF = 5 * 60  # 5 minutes in seconds

# Fetch Discord Webhook URL from environment variables
DISCORD_WEBHOOK_URL = os.getenv("FRIGATE_DISCORD_WEBHOOK")

# Tool functions
def mqtt_topic_matches(pattern, topic):
    # Convert MQTT wildcard pattern to regex pattern
    pattern = pattern.replace('+', '[^/]+').replace('#', '.*')
    regex = f"^{pattern}$"
    return re.match(regex, topic) is not None

def is_dark_now():
    # Define the timezone offset for Hilversum (CET or CEST)
    # CET is UTC+1, and CEST is UTC+2
    now = datetime.now(datetime.timezone.utc)
    is_dst = time.localtime().tm_isdst > 0
    timezone_offset = timedelta(hours=2 if is_dst else 1)
    
    # Create an observer for Hilversum
    observer = ephem.Observer()
    observer.lat = latitude
    observer.lon = longitude
    observer.date = now
    
    # Calculate sunrise and sunset times in UTC
    sunrise = observer.next_rising(ephem.Sun()).datetime()
    sunset = observer.next_setting(ephem.Sun()).datetime()
    
    # Adjust times to local timezone
    local_now = now + timezone_offset
    local_sunrise = sunrise + timezone_offset
    local_sunset = sunset + timezone_offset
    
    # Calculate 1 hour before sunrise and 1 hour after sunset
    one_hour_before_sunrise = local_sunrise - timedelta(hours=1)
    one_hour_after_sunset = local_sunset + timedelta(hours=1)
    
    # Check if it's dark outside (1 hour after sunset or 1 hour before sunrise)
    return local_now > one_hour_after_sunset or local_now < one_hour_before_sunrise

# App logic functions
def on_connect(client, userdata, flags, rc):
    logging.debug(f"Connected with result code {rc}")
    for subscription in TOPIC_SUBSCRIPTIONS:
        client.subscribe(subscription)

def on_message(client, userdata, msg):
    logging.info(f"#> Received message on topic {msg.topic}")
    if mqtt_topic_matches(TOPIC_SUBSCRIPTIONS[0], msg.topic):
        lightId = "13"
        handle_person_achtertuin_detection(client, msg, lightId)
    elif mqtt_topic_matches(TOPIC_SUBSCRIPTIONS[1], msg.topic):
        lightId = "13"
        handle_manual_interrupt(client, msg, lightId)
    else:
        logging.warning(f"#> Unknown topic: {msg.topic}")


def handle_person_achtertuin_detection(client, msg, lightId):
    global lastAutomationTime, backOffTimers, switchOffTimers
    if msg.payload == b'1':
        if is_dark_now():
            if lightId in backOffTimers:
                backoffTime = time.time() - backOffTimers[lightId] 
                if backoffTime > TIMEOUT_SWITCH_ON_RESET:
                    logging.info("Deleting backoff timer, because %s is lower than %s" % (backoffTime, TIMEOUT_SWITCH_ON_RESET))
                    del backOffTimers[lightId]
                else:
                    logging.info("Canceling switch-on because backoff time remaining: %s " % backoffTime)
                    return
            else:
                logging.info("No backoff timer for %s, so we can switch on" % lightId)
            
            logging.info("Switching on, no backoff timer")
            client.publish("hue2mqtt/group/"+ lightId +"/set", '{"on":true}')
            logging.debug("Delayed switchoff scheduled")
            # Cancel the previous timer if it exists
            if lightId in switchOffTimers:
                switchOffTimers[lightId].cancel()
            timer = threading.Timer(TIMEOUT_SWITCH_OFF, switch_off, args=(client, lightId))
            switchOffTimers[lightId] = timer  # Store the new timer
            timer.start()
            with lastAutomationTimeLock:
                lastAutomationTime["group/"+lightId] = time.time()

def handle_manual_interrupt(client, msg, lightId):
    global lastAutomationTime, backOffTimers
    payload = json.loads(msg.payload)
    if ("group/"+ lightId) in lastAutomationTime:
        logging.info("New action found")
        if payload.get("action").get("on") == False:
            logging.info("In manual backoff")
            backOffTimers[lightId] = time.time()
            # if lastAutomationTime["group/"+lightId] - time.time() < TIMEOUT_SWITCH_ON_RESET:
            #     client.publish("hue2mqtt/group/"+ lightId +"/set", '{"on":true}')
            #     with lastAutomationTimeLock:
            #         lastAutomationTime["group/"+lightId] = time.time()
            # else:
            #     with lastAutomationTimeLock:
            #         lastAutomationTime["group/"+lightId] = time.time()
            
        # else:
        #     client.publish("hue2mqtt/group/"+ lightId +"/set", '{"on":true}')
        #     with lastAutomationTimeLock:
        #         lastAutomationTime["group/"+lightId] = time.time()
            

def switch_off(client, lightId):
    logging.debug("Delayed switchoff started")
    with lastAutomationTimeLock:
        if time.time() - lastAutomationTime["group/"+lightId] > TIMEOUT_SWITCH_OFF:
            client.publish("hue2mqtt/group/"+ lightId +"/set", '{"on":false}')


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
        time.sleep(2)  # Sleep for 1 second
except KeyboardInterrupt:
    logging.error("Script interrupted")
finally:
    client.loop_stop()  # Stop the loop when done