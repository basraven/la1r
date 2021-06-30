#!/bin/sh
NODE_NAME=raspi2
if [ -f "/var/log/node_exporter/directory_size_$NODE_NAME.prom" ] ; then
    rm "/var/log/node_exporter/directory_size_$NODE_NAME.prom"
fi
/etc/node_exporter/directory-size.sh  "/mnt/hdd/ha" "/var/log/node_exporter/directory_size_$NODE_NAME.prom"
/etc/node_exporter/directory-size.sh  "/mnt/hdd/na" "/var/log/node_exporter/directory_size_$NODE_NAME.prom"