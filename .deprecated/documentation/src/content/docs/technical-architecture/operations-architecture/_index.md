---
bookToc: true
bookCollapseSection : true
---

## Operations architecture
To operate the infrastructure several tools are currently in use:
* Prometheus - on Kubernetes
* Grafana - on Kubernetes
* node_exporter - on metal (to be replaced by CollectD if feature complete, including top processes)
* Kibana - on Kubernetes (coming soon!)
* CollectD - on metal (coming soon!)
* SNMP - on CollectD (coming soon!)

### What and why
The following table shows what is being monitored and why   :

| Monitoring item name                              | Implementation Status                                             | Data Source           | Reason for Monitoring                                                     | Dashboard Link                                            | Associated Alert with Threshold(s)    |
| ---                                               | ---                                                               | ---                   | ---                                                                       | ---                                                       | ---                                   |
| Non-running Kubernetes Pods in replicaSet         | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | CollectD              | Will show if deployment is healthy                                        |                                                           | If > 0                                |
| Node CPU                                          | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if node has sufficient resources                                |                                                           | If > 80% over last hour               |
| Node Memory                                       | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if node has sufficient resources                                |                                                           | If > 80% over last hour               |
| Node Network                                      | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if node has sufficient resources                                |                                                           | If > 80% over last hour               |
| Node Disk IO                                      | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if node has sufficient resources                                |                                                           | If > 80% over last hour               |
| Node Uptime                                       | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if node needs restart                                           |                                                           | -                                     |
| Node Top Processes                                | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | node_exporter         | Will show if there are very heavy processes                               |                                                           | -                                     |
| Network usage spikes from any device on LAN       | ![](https://img.shields.io/badge/Status-To_be_developed-orange)   | snmp                  | Will show if a network device is using a significant amount of bandwidth  |                                                           | If > 50% over last 15 minutes         |