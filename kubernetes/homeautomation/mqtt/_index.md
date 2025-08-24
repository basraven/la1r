# MQTT Broker (Eclipse Mosquitto)

This directory contains the manifests for deploying an MQTT broker (Eclipse Mosquitto) in the `homeautomation` namespace.

## Overview
The MQTT broker acts as the central message bus for home automation, enabling communication between sensors, automations, and other services such as Frigate, Hue, and Discord bridges.

## Key Components

### 1. Deployment (`mqtt.yml`)
- **Image**: Uses `eclipse-mosquitto:latest`.
- **Configuration**: Loads its configuration from a ConfigMap (`mosquitto-config`) that sets up listener port 1883 and allows anonymous access (can be secured as needed).
- **Node Affinity**: Pinned to nodes with the `la1r.workload/specificonly=true` label.
- **Persistent Storage**: (Commented out) Can be configured to use a persistent volume for message storage if needed.

### 2. Persistent Storage (`pv/`)
- **mqtt-data-pv**: 150Mi hostPath volume for Mosquitto data.
- **mqtt-config-claim**: PVC for configuration data, referencing a storage class and label.

### 3. Networking
- **Service**: Exposes the broker on port 1883 as a ClusterIP for use within the cluster.
- **(Optional)**: Can be exposed as a LoadBalancer for LAN access (commented out in the manifest).

## Directory Structure
- `mqtt.yml`: Deployment, ConfigMap, and Service manifests.
- `pv/`: PersistentVolume and PersistentVolumeClaim manifests for data and config.
- `kustomization.yaml`: Kustomize entrypoint for this app.

## Integration
- **Home Automation**: Used by Frigate, Hue, Discord, and other services for event-driven automation.

## References
- [Eclipse Mosquitto Documentation](https://mosquitto.org/)
