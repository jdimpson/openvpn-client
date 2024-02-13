#!/bin/sh

# name of running container
NAME=openvpn

# client config file as it appears in the container
OVPNCLIENT="/etc/openvpn/myclient.ovpn"

# the CIDR address of the local subnet where the container host runs.
LOCALSUBNET="192.168.1.0/24"

# the port on the container host that will be forwarded in to the openvpn-client container
LPORT=8888

ETH="eth0";
MACVLAN="macvlan0";
RANGE="192.168.1.200/30";
GW="192.168.1.1";
echo "WARNING: This will create new docker macvlan network called $MACVLAN attached to $ETH with addresses in the range $RANGE using $GW as the gateway. It will delete the network after the docker run command exists, unless the script is killed with prejudice.";

docker network create -d macvlan -o parent=$ETH --subnet $LOCALSUBNET --gateway $GW --ip-range $RANGE $MACVLAN
trap  "docker network rm $MACVLAN" EXIT;

docker run -it --rm \
	--name="$NAME" \
	--cap-add=NET_ADMIN \
	--net=macvlan0 \
	--device=/dev/net/tun:/dev/net/tun \
	--mount type=bind,source="$(pwd)/",target="/etc/openvpn/" \
	-e OVPNCLIENT="$OVPNCLIENT" \
	-e LOCALSUBNET="$LOCALSUBNET" \
	-p 8888:8888/tcp \
	jdimpson/openvpn-client:latest

exit 0;
