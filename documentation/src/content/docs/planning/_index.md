---
title: Planning
type: docs
bookToc: false
weight: 99
---
# What's next?
Since I'm (currently) only developing la1r by myself, there are only so many things you can do at once. 
(Feel free to reach out through Github if you want to get involved!)
For this reason I created this planning page in which I track and prioritize what I will add to la1r next.
Feel free to add comments on this through Github!

# In progress
1. Traefik auth proxy middleware with Authelia

# Planned
1. Deploy a Kafka bus as structured event bus instead of mqtt
1. Spark 2.x Cluster in k8s
1. Streaming analyitics pipeline with Spark 2.x and Kafka
1. An event data dashboard for kafka
1. Streaming Facial recognition from images and streaming video
1. Object recognition (garbage bin outside of our house) combined with garbage collection ical (https://inzamelkalender.gad.nl/ical/0402200001574396)
1. Formal managed bare-metal security camera setup
1. "View in repo" button for all pages of the la1r documentation. While reading documentation, for example about Ansible, the visitor should be able to view which scripts are currently discussed by clicking a button to the git repository.
1. Refactor mosquitto to [vernemq](https://vernemq.com/)


# Parked
1. Ceph file system based rook.io or on this guide: https://owncloud.org/news/running-owncloud-in-kubernetes-with-rook-ceph-storage-step-by-step/

# Completed
1. Refactor backup facilities to use compression and dual backup (weekly and bi-daily)
1. OpenLDAP implementation
1. Formal service bus definition and separation of raw data and defined event data in MQTT
1. find-lf - wifi tracking as input events on the Event Bus based on AI models