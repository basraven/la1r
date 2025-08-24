# Frigate NVR Kubernetes Deployment

This directory contains all manifests and configuration for deploying Frigate NVR in the `homeautomation` namespace of the la1r Kubernetes cluster.

## Overview
Frigate is an open-source NVR (Network Video Recorder) with real-time object detection for IP cameras. This deployment is highly customized for hardware acceleration (Coral TPU), persistent storage, and integration with the la1r MQTT/Discord automation ecosystem.

## Key Components

### 1. Deployment (`frigate.yml`)
- **Image**: Uses `ghcr.io/blakeblackshear/frigate:stable`.
- **Node Affinity**: Pinned to nodes with the `la1r.workload/specificonly=true` label.
- **Hardware Integration**:
  - Mounts `/dev/video11` and `/dev/bus/usb` for video and Coral TPU access.
  - Uses an in-memory volume (`emptyDir`) for `/dev/shm`.
- **Configuration**:
  - Loads `config.yml` from a ConfigMap.
  - Mounts persistent volumes for both Frigate data and configuration.
- **Security**: Runs as privileged for hardware access.

### 2. Persistent Storage (`pv/`)
- **frigate-data-pv**: 50Gi hostPath volume for recordings and clips.
- **frigate-settings-data-pv**: 500Mi hostPath volume for persistent configuration.
- **PVCs**: Claims for both volumes are defined and referenced in the deployment.

### 3. Networking
- **Service**: Exposes Frigate on port 80 within the cluster and as a LoadBalancer with a fixed IP for LAN access.
- **Ingress**: Exposes Frigate at `https://frigate.bas` with a TLS certificate from cert-manager.

### 4. Configuration (`config.yml`)
- **MQTT**: Publishes events to the local `mqtt` broker for integration with home automation.
- **Detectors**: Configured for Coral TPU hardware acceleration.
- **Cameras**: Example camera configs for `voortuin` and `achtertuin` with motion masks and RTSP streams.
- **Recording & Retention**: Records all motion, with event- and snapshot-based retention controls.
- **Birdseye & Audio**: Disabled by default for performance.
- **Snapshots**: Configured for event-based image publishing and MQTT integration.

## Directory Structure
- `frigate.yml`: Main deployment, services, ingress, and certificate.
- `config.yml`: Frigate configuration (mounted via ConfigMap).
- `pv/`: PersistentVolume and PersistentVolumeClaim manifests for data and config.
- `kustomization.yaml`: Kustomize entrypoint for this app.

## Integration
- **MQTT**: Publishes detection events and snapshots for use by other automations (e.g., Discord alerts).
- **Discord**: See the `discord` app in this namespace for how MQTT events are bridged to Discord notifications.

## References
- [Frigate NVR Documentation](https://docs.frigate.video/)
