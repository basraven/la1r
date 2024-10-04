import logging
from kubernetes import client, config, watch
import requests
import json
import time
import os
from requests.exceptions import RequestException
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# Configure logging to write to stdout
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

RECHECK_INTERVAL = int(os.environ.get('RECHECK_INTERVAL', "60"))
SWITCH_IP = os.environ.get('SWITCH_IP', "192.168.5.2")
SWITCH_PORT = os.environ.get('SWITCH_PORT', "50505")
SWITCH_NUMBER = os.environ.get('SWITCH_NUMBER', "3")
OVERRIDE_FILE = os.environ.get('OVERRIDE_FILE', "/etc/re-lease/re-lease-override")

# Load kubeconfig from default location
config.load_kube_config(config_file="/etc/kubernetes/admin.conf")

# Create a Kubernetes API client
api_instance = client.AppsV1Api()

def check_override_file():
    while True:
        try:
            with open(OVERRIDE_FILE, 'r') as file:
                content = file.read().strip()
                if content:
                    logging.info(f"Override file {OVERRIDE_FILE} has content. Waiting {RECHECK_INTERVAL} seconds before checking again.")
                    time.sleep(RECHECK_INTERVAL) # Wait for 60 seconds before checking again
                else:
                    return # Exit the function if the file is empty
        except FileNotFoundError:
            return
        except IOError as e:
            logging.error(f"Error reading override file: {e}")
            return

def get_switch_url(action):
    return f"http://{SWITCH_IP}:{SWITCH_PORT}/api/v1/{action}/{SWITCH_NUMBER}"

def send_switch_request(url):
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()
        return response
    except RequestException as e:
        logging.error(f"Failed to send {url} to switch: {e}")
        return None

def check_deployments_with_labels():
    """Check existing deployments for the required labels and manage switch accordingly."""
    while True:
        try:
            deployments = api_instance.list_deployment_for_all_namespaces()
        except Exception as e:
            logging.error(f"Failed to list deployments: {e}")
            return


        deploys_needing_scaleup = []
        for deployment in deployments.items:
            if deployment.metadata and deployment.metadata.labels and 'sablier.enable' in deployment.metadata.labels and 'sablier.group' in deployment.metadata.labels and deployment.spec and deployment.spec.replicas:
                if deployment.spec.replicas > 0:
                    logging.info(f"Deployment {deployment.metadata.name} has scaling {deployment.spec.replicas}")
                    deploys_needing_scaleup.append(deployment.metadata.name)

        status_response = send_switch_request(get_switch_url("status"))
        if not status_response:
            return

        state = json.loads(status_response.text)["State"]
        if len(deploys_needing_scaleup) > 0:
            logging.info("At least one deployment has scaling above 0.")
            if state == 0 or state == 2 :
                on_response = send_switch_request(get_switch_url("start"))
                if on_response:
                    if "Device is switched on" not in on_response.text:
                        logging.warning("Response: Switch {SWITCH_NUMBER} could not be switched on")
                    elif "is already switched on" in on_response.text:
                        logging.info(f"Response: Switch {SWITCH_NUMBER} is already ON")
                    else:
                        logging.info(f"Response: Switch {SWITCH_NUMBER} turned ON")
            else:
                logging.info(f"Switch {SWITCH_NUMBER} is already ON")
        else:
            logging.info("No deployments with scaling above 0 found, switching off server.")
            if state == 1:
                off_response = send_switch_request(get_switch_url("stop"))
                if off_response:
                    if "already OFF" in off_response.text:
                        logging.info(f"Response: Switch {SWITCH_NUMBER} is already OFF")
                    elif "is switched OFF" in off_response.text:
                        logging.warning(F"Response: Switch {SWITCH_NUMBER} could not be switched off")
                    else:
                        logging.info(f"Response: Switch {SWITCH_NUMBER} turned OFF")
            else:
                logging.info(f"Switch {SWITCH_NUMBER} is already OFF")
        
        time.sleep(RECHECK_INTERVAL) # Ticks every N seconds



def main():
    logging.info(f"Starting the re-release with sleep interval: {RECHECK_INTERVAL} seconds.")
    while True:
        check_override_file()
        check_deployments_with_labels()
        time.sleep(RECHECK_INTERVAL)

if __name__ == "__main__":
    main()





# def watch_deployments_with_labels():
#     """Watch deployments for the required labels and manage switch accordingly."""
#     w = watch.Watch()
#     try:
#         for event in w.stream(api_instance.list_deployment_for_all_namespaces):
#             deployment = event['object']
#             if deployment.metadata and deployment.metadata.labels:
#                 if 'sablier.enable' in deployment.metadata.labels and 'sablier.group' in deployment.metadata.labels:
#                     if deployment.spec and deployment.spec.replicas:
#                         print("Deployment %s has scaling %d" % ( deployment.metadata.name, deployment.spec.replicas))
#                         if deployment.spec.replicas > 0:
#                             manage_switch_based_on_scaling()
#                         #  else:
#                             #   manage_switch_based_on_scaling()
            
#     except Exception as e:
#         logging.error(f"Error watching deployments: {e}")

# def manage_switch_based_on_scaling():
#     status_response = send_switch_request(get_switch_url("status"))
#     if not status_response:
#          return
#     # logging.info("At least one deployment has scaling above 0.")
#     response = json.loads(status_response.text)
#     if response["State"] == 0 or response["State"] == 2:
#         on_response = send_switch_request(get_switch_url("start"))
#         if on_response:
#             logging.info(f"Response: Switch {SWITCH_NUMBER} turned ON")
#     else:
#         logging.info(f"Switch {SWITCH_NUMBER} is already ON")
    # if has_scaling_above_zero:
    # else:
    #     logging.info("No deployments with scaling above 0 found, switching off server.")
    #     if json.loads(status_response.text)["State"] == 1:
    #         off_response = send_switch_request(get_switch_url("stop"))
    #         if off_response:
    #             logging.info(f"Response: Switch {SWITCH_NUMBER} turned OFF")
    #     else:
    #         logging.info(f"Switch {SWITCH_NUMBER} is already OFF")

