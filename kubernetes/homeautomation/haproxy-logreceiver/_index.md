# HAProxy Log Receiver

This document describes the function and usage of the HAProxy Log Receiver in the la1r Kubernetes cluster.

## Overview
The HAProxy Log Receiver listens for UDP syslog messages from HAProxy, parses backend server state changes, and can trigger lease requests or other automation. It is used for dynamic service discovery, monitoring, and home automation workflows.

## Key Components
- **Deployment/Service YAMLs**: Kubernetes manifests to deploy the log receiver as a service within the cluster.
- **Go Source Code**: Implements the UDP log receiver and backend state parser.
- **ConfigMap/Secret**: (If present) for runtime configuration.

## Usage
- Deploy the manifests in this directory to run the log receiver service.
- Point HAProxy's syslog output to the service's UDP port.
- Monitor logs and backend events, or extend the code to trigger additional automation as needed.

## References
- [HAProxy Documentation](https://www.haproxy.org/download/)
- [Syslog Protocol](https://datatracker.ietf.org/doc/html/rfc5424)