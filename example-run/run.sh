#!/bin/sh

if ! test -r myclient.ovpn; then
	echo "this example script needs an openvpn client configuration file to run." >&2;
	echo "it should be called myclient.ovpn" >&2;
	echo "and it should be located in the current directory." >&2;
	exit 1;
fi

# name of running container
NAME=openvpn

# client config file as it appears in the container
OVPNCLIENT="/etc/openvpn/myclient.ovpn"

# the CIDR address of the local subnet where the container host runs.
LOCALSUBNET="192.168.1.0/24"
# this value isnt important unless you intend to use the built in tinyproxy process, 
# or for the more advanced routing configurations found in run-macvlan.sh or run-host.sh

# the port on the container host that will be forwarded in to the openvpn-client container
LPORT=8888
# make sure LOCALSUBNET is set correctly to your home network if you want to use 
# tinyproxy

docker run -it --rm \
	--name="$NAME" \
	--cap-add=NET_ADMIN \
 	--device=/dev/net/tun:/dev/net/tun \
	--mount type=bind,source="$(pwd)/",target="/etc/openvpn/" \
	-e OVPNCLIENT="$OVPNCLIENT" \
	-e LOCALSUBNET="$LOCALSUBNET" \
	-p $LPORT:8888/tcp \
	jdimpson/openvpn-client:latest
