#!/bin/sh

# name of running container
NAME=openvpn

# client config file as it appears in the container
OVPNCLIENT="/etc/openvpn/myclient.ovpn"

# the CIDR address of the local subnet where the container host runs.
LOCALSUBNET="192.168.1.0/24"

# the port on the container host that will be forwarded in to the openvpn-client container
LPORT=8888

echo "WARNING: This will change the default route of the container host to that of the VPN. If you are connecting to the container host from a remote network (i.e. not on console, and not from the local subnet) you are likely to lose connectivity to this host. Also, any other network connections are likely to be interrupted. Press Control-C to quit, or Enter to continue.";
read x;

docker run -it --rm \
	--name="$NAME" \
	--cap-add=NET_ADMIN \
	--net=host \ 
	--device=/dev/net/tun:/dev/net/tun \
	--mount type=bind,source="$(pwd)/",target="/etc/openvpn/" \
	-e OVPNCLIENT="$OVPNCLIENT" \
	-e LOCALSUBNET="$LOCALSUBNET" \
	-p 8888:8888/tcp \
	jdimpson/openvpn-client:latest
