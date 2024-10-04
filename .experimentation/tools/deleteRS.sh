#!/bin/bash

# Get all ReplicaSets with desired replicas set to 0
replica_sets=$(kubectl get rs --all-namespaces -o jsonpath='{range .items[?(@.spec.replicas==0)]}{.metadata.namespace}{" "}{.metadata.name}{"\n"}{end}')

# Check if any ReplicaSets found
if [ -z "$replica_sets" ]; then
  echo "No ReplicaSets with desired replicas set to 0 found."
  exit 0
fi

# Loop through each ReplicaSet and delete it
while read -r namespace name; do
  echo "Deleting ReplicaSet: $name in namespace: $namespace"
  kubectl delete rs "$name" -n "$namespace"
done <<< "$replica_sets"
