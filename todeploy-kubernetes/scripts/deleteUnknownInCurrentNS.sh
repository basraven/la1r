#!/bin/bash
for each in $(kubectl get pods |grep Unknown|awk '{print $1}');
do
  #echo $each
  kubectl delete pods $each
done
