# Discord Integrations

## Overview
This directory contains two integrations with Discord:
- **Frigate MQTT to Discord Bridge**: Sends person detection events from Frigate NVR to a Discord channel.
- **Flux CD Alerting**: Sends GitOps alerts from Flux CD to a Discord channel.

## Key Components
- `discord.yml`: Deployment for the Frigate-to-Discord bridge (Python app, MQTT to Discord webhook).
- `discord-flux-system.yml`: Flux CD Provider and Alert manifests for GitOps notifications.
- `mqtt_to_discord.py`: Python script for Frigate event processing.
- `kustomization.yaml`: Kustomize entrypoint for all resources.
- **Secrets**: Webhook URLs for Discord are stored in Kubernetes secrets.

## Usage
- Deploy `discord.yml` to enable Frigate event notifications in Discord.
- Deploy `discord-flux-system.yml` to enable Flux CD alerts in Discord.
- Configure webhooks/secrets as described in the manifests.
- For details on each integration, see the respective YAML and Python files.

## References
- [Frigate NVR Documentation](https://docs.frigate.video/)
- [Flux CD Notifications](https://fluxcd.io/flux/components/notification/)
