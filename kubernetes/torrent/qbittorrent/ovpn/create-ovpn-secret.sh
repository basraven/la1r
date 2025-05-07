#!/bin/bash
kubectl -n torrent create secret generic goose-ovpn-files \
  --from-file=qbitorrent.ovpn=cezch-iponly.ovpn \
  --from-file=qbitorrent-series.ovpn=poland-iponly.ovpn \
  --from-file=qbitorrent-uhd.ovpn=sweden-iponly.ovpn