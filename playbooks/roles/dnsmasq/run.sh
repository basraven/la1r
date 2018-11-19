#!/bin/bash
docker build . -t dnsmasq
docker rm -f dnsmasq
docker run -d --name dnsmasq --restart always --net=host -v /home/basraven/dnsmasq/etc/:/etc/dnsmasq.d --cap-add=NET_ADMIN dnsmasq