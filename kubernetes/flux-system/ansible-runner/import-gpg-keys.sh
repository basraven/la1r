#!/bin/bash
kubectl -n ansible create secret generic gpg-automated-keys \
  --from-file=../../../automation-gpg-private.asc \
  --from-file=../../../automation-gpg-public.asc
  