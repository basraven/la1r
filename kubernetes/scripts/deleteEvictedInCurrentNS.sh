#!/bin/bash
for each in $(kubectl get pods |grep Evicted|awk '{print $1}');
do
  #echo $each
  kubectl delete pods $each
done
