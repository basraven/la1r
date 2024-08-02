#!/bin/bash

kubectl taint node linux-wayne node-role.kubernetes.io/control-plane:NoSchedule-
kubectl label nodes linux-wayne la1r.workload/essential=true
kubectl label nodes jay-c la1r.workload/nonessential=true

kubectl label nodes jay-c la1r.storage/ssd-ha=true
kubectl label nodes jay-c la1r.storage/ssd-na=true
kubectl label nodes jay-c la1r.storage/hdd-ha=true
kubectl label nodes jay-c la1r.storage/hdd-na=true

kubectl label nodes linux-wayne la1r.storage/ssd-ha=true
kubectl label nodes linux-wayne la1r.storage/ssd-na=true
kubectl label nodes linux-wayne la1r.storage/hdd-ha=true
kubectl label nodes linux-wayne la1r.storage/hdd-na=true

# for metallb
kubectl label node linux-wayne node.kubernetes.io/exclude-from-external-load-balancers-
kubectl label node jay-c node.kubernetes.io/exclude-from-external-load-balancers-





# ---
# apiVersion: v1
# kind: Node
# metadata:
#   name: linux-wayne
#   labels:
#     la1r.storage/111: "false"
#     la1r.storage/211: "false"
#     la1r.storage/221: "false"
#     la1r.storage/112: "false"
#     la1r.storage/212: "false"
#     la1r.storage/222: "false"

# ---
# apiVersion: v1
# kind: Node
# metadata:
#   name: jay-c
#   labels:
#     la1r.storage/ssd-ha: "true"
    # la1r.storage/111: "true"
    # la1r.storage/211: "true"
    # la1r.storage/221: "true"
    # la1r.storage/112: "true"
    # la1r.storage/212: "true"
    # la1r.storage/222: "true"
