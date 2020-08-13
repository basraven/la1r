---
title: Planning
type: docs
bookToc: false
weight: 99
---
## What's next?
Since I'm (currently) only developing la1r by myself, there are only so many things you can do at once. 
(Feel free to reach out through Github if you want to get involved!)
For this reason I created this planning page in which I track and prioritize what I will add to la1r next.
Feel free to add comments on this through Github!

## In progress
1. New network configuration with new network hardware
2. NFS based dynamic storage provisioning
3. New multi-cluster setup with kube-proxy

## Planned
4. Metallb implementation
5. CollectD, replacing node_exporter
6.  New doorbell security firmware
7.  Video security storage process   
8.  kube-state-metrics in grafana
9.  DNS black-hole with pihole
10. Grafana backup script with: https://github.com/ysde/grafana-backup-tool
11. Kibana log analysis
12. Fail2ban new filters for ALL services
13. Traefik auth proxy middleware with Authelia
14. "View in repo" button for all pages of the la1r documentation. While reading documentation, for example about Ansible, the visitor should be able to view which scripts are currently discussed by clicking a button to the git repository.
15. find-lf - wifi tracking as input events on the Event Bus based on AI models


## Longstay parking
16. Deploy a Kafka bus as structured event bus instead of mqtt
17. Spark 2.x Cluster in k8s
18. Streaming analytics pipeline with Spark 2.x and Kafka
19. An event data dashboard for kafka
20. Streaming Facial recognition from images and streaming video
21. Formal managed bare-metal security camera setup
22. Object recognition (garbage bin outside of our house) combined with garbage collection iCal (https://inzamelkalender.gad.nl/ical/0402200001574396)
23. Refactor Mosquito to [vernemq](https://vernemq.com/) 

## Completed
1. Kerberos setup
2. Metallb tests
3. new dns configuration
4. Refactor backup facilities to use compression and dual backup (weekly and bi-daily)
5. OpenLDAP implementation
6. Formal service bus definition and separation of raw data and defined event data in MQTT
