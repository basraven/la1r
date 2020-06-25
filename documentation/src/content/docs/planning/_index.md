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
1. New network configuration
1. Prototype based configuration management

## Planned
1. Grafana backup script with: https://github.com/ysde/grafana-backup-tool
2. GoCD CI/CD for prototype based config management (2 ways)
3. Kibana log analysis
4. Fail2ban new filters for ALL services
5. Traefik auth proxy middleware with Authelia
6. MetalLB tests
7. "View in repo" button for all pages of the la1r documentation. While reading documentation, for example about Ansible, the visitor should be able to view which scripts are currently discussed by clicking a button to the git repository.
8. Deploy a Kafka bus as structured event bus instead of mqtt
9.  Spark 2.x Cluster in k8s
10. Streaming analytics pipeline with Spark 2.x and Kafka
11. An event data dashboard for kafka
12. Streaming Facial recognition from images and streaming video
13. Object recognition (garbage bin outside of our house) combined with garbage collection iCal (https://inzamelkalender.gad.nl/ical/0402200001574396)
14. Formal managed bare-metal security camera setup
15. Refactor Mosquito to [vernemq](https://vernemq.com/)

## Parked
1. Ceph file system based rook.io or on this guide: https://owncloud.org/news/running-owncloud-in-kubernetes-with-rook-ceph-storage-step-by-step/

## Completed

1. new dns configuration
1. Refactor backup facilities to use compression and dual backup (weekly and bi-daily)
1. OpenLDAP implementation
1. Formal service bus definition and separation of raw data and defined event data in MQTT
1. find-lf - wifi tracking as input events on the Event Bus based on AI models
