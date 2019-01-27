#!/bin/sh
set -eu
echo "[OPENVPN] Creating GooseVPN connection"
apt-get update
apt-get install openvpn -y
# echo AUTOSTART="ro-10" >> /etc/default/openvpn
# service openvpn start
openvpn /etc/openvpn/ro-10.conf | sed "s/^/[OPENVPN] /" &
/init