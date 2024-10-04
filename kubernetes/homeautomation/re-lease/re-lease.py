import logging
from kubernetes import client, config, watch
import requests
import json
import os
from requests.exceptions import RequestException
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
import threading

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

class OverrideFileHandler(FileSystemEventHandler):
    def on_modified(self, event):
        if event.src_path == OVERRIDE_FILE:
            check_override_file()

def check_override_file():
    try:
        with open(OVERRIDE_FILE, 'r') as file:
            content = file.read().strip()
            if content:
                logging.info(f"Override file {OVERRIDE_FILE} has content.")
            else:
                logging.info(f"Override file {OVERRIDE_FILE} is empty.")
    except FileNotFoundError:
        logging.error(f"Override file {OVERRIDE_FILE} not found.")
    except IOError as e:
        logging.error(f"Error reading override file: {e}")

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
    """Watch deployments for the required labels and manage switch accordingly."""
    w = watch.Watch()
    try:
        for event in w.stream(api_instance.list_deployment_for_all_namespaces):
            deployment = event['object']
            if deployment.metadata.labels and 'sablier.enable' in deployment.metadata.labels and 'sablier.group' in deployment.metadata.labels:
                has_scaling_above_zero = deployment.spec.replicas > 0
                # manage_switch_based_on_scaling(has_scaling_above_zero)
    except Exception as e:
        logging.error(f"Error watching deployments: {e}")

def manage_switch_based_on_scaling(has_scaling_above_zero):
    status_response = send_switch_request(get_switch_url("status"))
    if not status_response:
        return

    if has_scaling_above_zero:
        logging.info("At least one deployment has scaling above 0.")
        if json.loads(status_response.json)["State"] == 1:
            on_response = send_switch_request(get_switch_url("start"))
            if on_response:
                logging.info(f"Response: Switch {SWITCH_NUMBER} turned ON")
        else:
            logging.info(f"Switch {SWITCH_NUMBER} is already ON")
    else:
        logging.info("No deployments with scaling above 0 found, switching off server.")
        if json.loads(status_response.json)["State"] == 1:
            off_response = send_switch_request(get_switch_url("stop"))
            if off_response:
                logging.info(f"Response: Switch {SWITCH_NUMBER} turned OFF")
        else:
            logging.info(f"Switch {SWITCH_NUMBER} is already OFF")

def start_file_watcher():
    """Start a watchdog observer to monitor file changes."""
    event_handler = OverrideFileHandler()
    observer = Observer()
    observer.schedule(event_handler, path=os.path.dirname(OVERRIDE_FILE), recursive=False)
    observer.start()
    observer.join()  # Keeps the observer running

def start_kubernetes_watcher():
    """Start a watcher for Kubernetes deployment events."""
    check_deployments_with_labels()

def main():
    logging.info("Starting the re-release event-driven watch.")
    
    # Create threads for file watcher and Kubernetes watcher
    file_watcher_thread = threading.Thread(target=start_file_watcher, daemon=True)
    kubernetes_watcher_thread = threading.Thread(target=start_kubernetes_watcher, daemon=True)

    # Start both threads
    file_watcher_thread.start()
    kubernetes_watcher_thread.start()

    # Join threads to keep them running in the background
    file_watcher_thread.join()
    kubernetes_watcher_thread.join()

if __name__ == "__main__":
    main()
