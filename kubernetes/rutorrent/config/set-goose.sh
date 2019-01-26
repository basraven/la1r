#!/bin/sh
set -eu
echo "Tuning the container..."
echo "connecting to Goose"
apk add openvpn
# cd /dev
# mkdir net
# cd net
# mknod tun c 10 200
# chmod 666 tun
# cd /etc/openvpn/
# # openvpn ro-10.ovpn | sed -e 's/^/OVPN: /;' &
# cd /
/init