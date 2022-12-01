#!/bin/bash
# (Execute on host)
kubectl -n dns create secret generic hostetcd --from-file=/etc/kubernetes/pki/etcd/ca.crt --from-file=/etc/kubernetes/pki/etcd/server.crt --from-file=/etc/kubernetes/pki/etcd/server.key