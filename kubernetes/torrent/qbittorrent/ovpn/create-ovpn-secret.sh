#!/bin/bash
# Rebuild the goose-credentials Secret (namespace torrent) from the current
# GooseVPN config bundle. Sources (gitignored): poland-pl2.ovpn, hungary-hu2.ovpn,
# login.conf. Run from this directory. Idempotent: ovpn keys no longer listed
# here are pruned from the Secret.
kubectl -n torrent create secret generic goose-credentials \
  --from-file=ovpn1.ovpn=poland-pl2.ovpn \
  --from-file=ovpn2.ovpn=hungary-hu2.ovpn \
  --from-file=login.conf=login.conf \
  --dry-run=client -o yaml | kubectl apply -f -
