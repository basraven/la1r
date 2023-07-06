#!/bin/bash
# This was used to bootstrap the CI:
flux bootstrap github   --owner=basraven   --repository=la1r --branch=rick  --path=./kubernetes --toleration-keys=la1r.workload/essential --personal