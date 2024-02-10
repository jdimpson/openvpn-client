#!/bin/sh
	#--mount type=bind,source="$(pwd)/feral-client.ovpn",target="/etc/openvpn/client.ovpn" \

# name of running container
NAME=openvpn

# client config file as it appears in the container
OVPNCLIENT="/etc/openvpn/myclient.ovpn"

# the CIDR address of the local subnet where the container host runs.
LOCALSUBNET="192.168.1.0/24"

# the port on the container host that will be forwarded in to the openvpn-client container
LPORT=8888

docker run -it --rm \
	--name="$NAME" \
	--cap-add=NET_ADMIN \
 	--device=/dev/net/tun:/dev/net/tun \
	--mount type=bind,source="$(pwd)/",target="/etc/openvpn/" \
	-e OVPNCLIENT="$OVPNCLIENT" \
	-e LOCALSUBNET="$LOCALSUBNET" \
	-p 8888:8888/tcp \
	jdimpson/openvpn-client:latest
