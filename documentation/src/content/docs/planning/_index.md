---
title: Planning
bookToc: false
weight: 99
---

## What's next?
Since I'm (currently) only developing la1r by myself, there are only so many things you can do at once. 
(Feel free to reach out through Github if you want to get involved!)
For this reason I created this planning page in which I track and prioritize what I will add to la1r next.
Feel free to add comments on this through Github!

## In progress
* node_exporter in DaemonSet: https://github.com/prometheus-operator/kube-prometheus/blob/master/manifests/node-exporter-daemonset.yaml

## Planned
* Backup reimplementation
* Apache airflow to integrate with streaming pipelines for event-driven home: https://airflow.apache.org/docs/stable/kubernetes.html
*  Online reimplementation
*  Home automation reimplementation

## Longstay parking
* SNMP of DHCP server to consul/nodes for live node status info (added with a health check / ping performed by consul)
* New doorbell security firmware
* Video security storage process   
* Grafana backup script with: https://github.com/ysde/grafana-backup-tool
* Fail2ban new filters for ALL services
* Traefik auth proxy middleware with Authelia
* "View in repo" button for all pages of the la1r documentation. While reading documentation, for example about Ansible, the visitor should be able to view which scripts are currently discussed by clicking a button to the git repository.
* find-lf - wifi tracking as input events on the Event Bus based on AI model
* Cronacle cron manager https://github.com/jhuckaby/Cronicle
* Deploy a Kafka bus as structured event bus instead of mqtt
* Spark 2.x Cluster in k8s
* Streaming analytics pipeline with Spark 2.x and Kafka
* An event data dashboard for kafka
* Streaming Facial recognition from images and streaming video
* Formal managed bare-metal security camera setup
* Object recognition (garbage bin outside of our house) combined with garbage collection iCal (https://inzamelkalender.gad.nl/ical/0402200001574396)
* Refactor Mosquito to [vernemq](https://vernemq.com/) 

## Completed
* Kibana log analysis
* Monitoring with kube-state-metrics in grafana
* Monitoring extension, e.g. with alert manager and https://github.com/benjojo/alertmanager-discord
* Prometheus alert manager implementation and https://awesome-prometheus-alerts.grep.to/rules.html
* DNS black-hole with pihole 
* Monitoring reimplementation
* DNS on LAN implementation
* Traefik 2.x reimplementation
* Metallb implementation
* NFS based dynamic storage provisioning
* New multi-cluster setup with kube-proxy
* New network configuration with new network hardware
* Kerberos setup
* Metallb tests
* new dns configuration
* Refactor backup facilities to use compression and dual backup (weekly and bi-daily)
* OpenLDAP implementation
* Formal service bus definition and separation of raw data and defined event data in MQTT