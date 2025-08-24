# Traefik Watcher

This document describes the function and usage of the Traefik Watcher utility for Jellyfin in the la1r Kubernetes cluster.

## Overview
The Traefik Watcher monitors traffic metrics from Traefik, specifically for the Jellyfin media server. It checks for specific HTTP status codes and entrypoints, enabling alerting or automation based on observed traffic patterns (such as 404 errors).

## Key Components
- **Metric Monitored**: `traefik_entrypoint_requests_total{code="404",entrypoint="jellyfin",method="GET",protocol="http"}`
- **Watcher Script/Service**: (If present) Consumes metrics and triggers alerts or actions.

## Usage
- Deploy or run the watcher utility as described in this directory.
- Configure Prometheus or metric scraping to ensure the metric is available.
- Use the watcher to trigger notifications or automation based on traffic anomalies.

## References
- [Traefik Metrics Documentation](https://doc.traefik.io/traefik/observability/metrics/prometheus/)
