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
1.  DNS on LAN implementation

## Planned
2. Nextcloud reimplementation
3. Backup reimplementation
4. Torrent reimplementation
5. Monitoring reimplementation
6. Monitoring with kube-state-metrics in grafana
7. Monitoring extension
8.  DNS black-hole with pihole
9.  Online reimplementation
10. Home automation reimplementation

## Longstay parking
13. CollectD, replacing node_exporter
14. New doorbell security firmware
15. Video security storage process   
16. Grafana backup script with: https://github.com/ysde/grafana-backup-tool
17. Kibana log analysis
18. Fail2ban new filters for ALL services
19. Traefik auth proxy middleware with Authelia
20. "View in repo" button for all pages of the la1r documentation. While reading documentation, for example about Ansible, the visitor should be able to view which scripts are currently discussed by clicking a button to the git repository.
21. find-lf - wifi tracking as input events on the Event Bus based on AI models
22. Deploy a Kafka bus as structured event bus instead of mqtt
23. Spark 2.x Cluster in k8s
24. Streaming analytics pipeline with Spark 2.x and Kafka
25. An event data dashboard for kafka
26. Streaming Facial recognition from images and streaming video
27. Formal managed bare-metal security camera setup
28. Object recognition (garbage bin outside of our house) combined with garbage collection iCal (https://inzamelkalender.gad.nl/ical/0402200001574396)
29. Refactor Mosquito to [vernemq](https://vernemq.com/) 

## Completed
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
