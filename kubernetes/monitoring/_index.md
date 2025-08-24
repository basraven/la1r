# Monitoring Stack

This directory contains manifests and configuration for monitoring tools deployed in the la1r Kubernetes cluster.

## Structure
- **grafana/**: Grafana dashboards and configuration for visualizing metrics.
- **prometheus/**: Prometheus deployment, service discovery, alerting rules, and exporters.
- **kustomization.yaml**: Kustomize entrypoint for all monitoring resources.
- **namespace.yml**: Namespace definition for grouping monitoring resources.

## Usage
- Apply the manifests in this directory to deploy monitoring tools and exporters.
- Access Grafana via its ingress for dashboards and Prometheus for raw metrics and alerting.
- For details on each component, see their respective subdirectories (e.g., `grafana/`, `prometheus/`).

## References
- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Documentation](https://grafana.com/docs/)
