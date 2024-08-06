#!/bin/bash
mkdir state
cp ovpn_env.sh state/
cd state

docker run --rm -v $PWD:/etc/openvpn kylemanna/openvpn ovpn_genconfig -u udp://vpn.la1r.com:33443

docker run --rm -v $PWD:/etc/openvpn -it kylemanna/openvpn ovpn_initpki nopass

docker run -v $PWD:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full sebtest nopass

docker run -v $PWD:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient sebtest > sebtest.ovpn