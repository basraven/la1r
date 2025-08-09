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
CONTROLLER_IP = os.environ.get('CONTROLLER_IP', "192.168.5.2")
CONTROLLER_PORT = os.environ.get('CONTROLLER_PORT', "50505")
TARGET_DEVICE_NUMBER = os.environ.get('TARGET_DEVICE_NUMBER', "3")
OVERRIDE_FILE = os.environ.get('OVERRIDE_FILE', "/etc/re-lease/re-lease-override")
TARGETNODE_LABEL = os.environ.get('TARGETNODE_LABEL', "la1r.workload/nonessential=true") 

# Load kubeconfig from default location
config.load_kube_config(config_file="/etc/kubernetes/admin.conf")

# Create a Kubernetes API client
api_instance = client.AppsV1Api()
core_api_instance = client.CoreV1Api()

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

def get_device_url(action):
    return f"http://{CONTROLLER_IP}:{CONTROLLER_PORT}/api/v1/{action}/{TARGET_DEVICE_NUMBER}"

def send_device_request(url):
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
            
            # Get nodes that match the label selector
            nodes = core_api_instance.list_node(label_selector=TARGETNODE_LABEL).items
            # Extract the names of the nodes that match the label
            filtered_node_names = {node.metadata.name for node in nodes}


        except Exception as e:
            logging.error(f"Failed to list deployments or nodes: {e}")
            return


        deploys_needing_scaleup = []
        for deployment in deployments.items:
            if deployment.metadata and deployment.metadata.labels and 'sablier.enable' in deployment.metadata.labels and 'sablier.group' in deployment.metadata.labels and deployment.spec and deployment.spec.replicas:
                if deployment.spec.replicas > 0:
                    if deployment.spec.template.spec.affinity:
                        targetKey, targetValue = TARGETNODE_LABEL.rsplit(sep='=', maxsplit=1)
                        if not deployment.spec.template.spec.affinity.node_affinity.required_during_scheduling_ignored_during_execution:
                            logging.info(f"Deployment {deployment.metadata.name} does not have affinity set up.")
                            continue
                        nodeSelector = deployment.spec.template.spec.affinity.node_affinity.required_during_scheduling_ignored_during_execution.node_selector_terms[0].match_expressions[0]
                        if nodeSelector.key == targetKey and targetValue in nodeSelector.values:
                            logging.info(f"Deployment {deployment.metadata.name} has scaling >0 and is targeting the correct node: {TARGETNODE_LABEL}")
                            deploys_needing_scaleup.append(deployment.metadata.name)
                            continue
                        else:
                            logging.info(f"Deployment {deployment.metadata.name} has scaling of 0 or isn't targeting the correct node: {TARGETNODE_LABEL}")
                            continue

        status_response = send_device_request(get_device_url("status"))
        if not status_response:
            return

        state = json.loads(status_response.text)["State"]
        if len(deploys_needing_scaleup) > 0:
            logging.info("At least one deployment has scaling above 0.")
            if state == 0 or state == 2 :
                on_response = send_device_request(get_device_url("start"))
                if on_response:
                    if "was switched on" not in on_response.text:
                        logging.warning("Response: Device {SWITCH_NUMBER} could not be switched on")
                    elif "was already on" in on_response.text:
                        logging.info(f"Response: Device {TARGET_DEVICE_NUMBER} was already on")
                    else:
                        logging.info(f"Response: Device {TARGET_DEVICE_NUMBER} turned on")
            else:
                logging.info(f"Device {TARGET_DEVICE_NUMBER} was already on")
        else:
            logging.info("No deployments with scaling above 0 found, switching off server.")
            if state == 1:
                off_response = send_device_request(get_device_url("stop"))
                if off_response:
                    if "was switched off" in off_response.text:
                        logging.info(f"Response: Device {TARGET_DEVICE_NUMBER} was switched off")
                    elif "was already off" in off_response.text:
                        logging.warning(F"Response: Device {TARGET_DEVICE_NUMBER} was already off")
                    else:
                        logging.info(f"Response: Device {TARGET_DEVICE_NUMBER} turned off")
            else:
                logging.info(f"Device {TARGET_DEVICE_NUMBER} was already off")
        
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
#             logging.info(f"Response: Device {SWITCH_NUMBER} turned on")
#     else:
#         logging.info(f"Device {SWITCH_NUMBER} is already on")
    # if has_scaling_above_zero:
    # else:
    #     logging.info("No deployments with scaling above 0 found, switching off server.")
    #     if json.loads(status_response.text)["State"] == 1:
    #         off_response = send_switch_request(get_switch_url("stop"))
    #         if off_response:
    #             logging.info(f"Response: Device {SWITCH_NUMBER} turned off")
    #     else:
    #         logging.info(f"Device {SWITCH_NUMBER} is already off")

