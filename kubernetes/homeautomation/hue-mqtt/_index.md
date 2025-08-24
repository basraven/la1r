# Hue to MQTT Bridge

This directory contains the manifests for deploying a bridge between Philips Hue and MQTT, enabling integration of Hue lights with the broader home automation system.

## Overview
The Hue-MQTT bridge allows events and state from a Philips Hue bridge to be published to an MQTT broker, making them available for automation and monitoring by other services.

## Key Components

### 1. Deployment (`hue-mqtt.yml`)
- **Image**: Uses `python:3.9-slim` and installs the `hue2mqtt` Python package at runtime.
- **Entrypoint**: Runs `hue2mqtt --config-file /config/hue2mqtt.toml`.
- **Configuration**:
  - Loads its configuration from a Kubernetes secret named `hue-config`, mounted at `/config/hue2mqtt.toml`.
- **Node Affinity**: Pinned to nodes with the `la1r.workload/specificonly=true` label for hardware or locality reasons.

### 2. Integration
- **MQTT**: Publishes Hue events and state to the local MQTT broker, allowing other automations (such as Home Assistant or custom scripts) to react to changes in Hue lights or sensors.
- **Secrets**: The configuration secret is not included here for security reasons. It must be created separately and contain the necessary credentials and Hue bridge information.

## Directory Structure
- `hue-mqtt.yml`: Deployment manifest for the bridge.
- `kustomization.yaml`: Kustomize entrypoint for this app.

## References
- [hue2mqtt GitHub](https://github.com/denpamusic/hue2mqtt)
