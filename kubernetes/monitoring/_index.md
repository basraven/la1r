# Monitoring Stack

This directory contains manifests and configuration for monitoring tools deployed in the la1r Kubernetes cluster.

## Structure
- **grafana/**: Grafana dashboards and configuration for visualizing metrics.
- **prometheus/**: Prometheus deployment, service discovery, alerting rules, and exporters.
- **uptime/**: Gatus uptime monitoring with Sablier-aware health checking.
- **ntfy/**: Notification service for alerts and events.
- **kubewatch/**: Kubernetes event watcher for cluster changes.
- **system-audit/**: Custom system auditing and health checks.
- **kustomization.yaml**: Kustomize entrypoint for all monitoring resources.
- **namespace.yml**: Namespace definition for grouping monitoring resources.

## Usage
- Apply the manifests in this directory to deploy monitoring tools and exporters.
- Access Grafana via its ingress for dashboards and Prometheus for raw metrics and alerting.
- Access the uptime status dashboard at [status.bas](https://status.bas).
- For details on each component, see their respective subdirectories (e.g., `grafana/`, `prometheus/`, `uptime/`).

## References
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Gatus Documentation](https://github.com/TwiN/gatus)
