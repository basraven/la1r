# MQTT Automation

This directory contains the manifests and source code for a custom MQTT automation service, deployed in the `homeautomation` namespace.

## Overview
This service runs a Python automation script that listens to MQTT topics (such as Frigate person detection and Hue group events) and performs smart automations, like switching on/off Hue lights based on detected motion and time of day.

## Key Components

### 1. Deployment (`mqtt-automation.yml`)
- **Image**: Uses `python:3.9-slim` and installs required Python packages (`paho-mqtt`, `ephem`, `requests`).
- **Entrypoint**: Runs the `mqtt_automation.py` script from a ConfigMap.
- **Node Affinity**: Pinned to nodes with the `la1r.workload/specificonly=true` label.
- **Time Sync**: Mounts the host's `/etc/localtime` for correct time calculations (essential for sunrise/sunset logic).

### 2. Application Logic (`mqtt_automation.py`)
- **MQTT Subscriptions**:
  - `frigate/achtertuin/person`: Triggers automation when a person is detected by Frigate in the backyard.
  - `hue2mqtt/group/13`: Monitors manual state changes of Hue group 13.
- **Automation Logic**:
  - Switches on Hue group 13 if a person is detected and it is dark (calculated using ephemeris data for Hilversum).
  - Implements backoff timers to avoid rapid toggling and respects manual overrides.
  - Switches off the light after a timeout, unless manually overridden.
- **Integrations**:
  - Can send Discord notifications if the `FRIGATE_DISCORD_WEBHOOK` environment variable is set.

### 3. ConfigMap
- The Python script is injected via a ConfigMap and mounted at runtime.

## Directory Structure
- `mqtt-automation.yml`: Deployment manifest for the automation service.
- `mqtt_automation.py`: Python automation script.
- `kustomization.yaml`: Kustomize entrypoint for this app.

## References
- [Paho MQTT Python](https://www.eclipse.org/paho/index.php?page=clients/python/index.php)
- [ephem (Astronomical calculations)](https://rhodesmill.org/pyephem/)
