#!/bin/sh

# name of running container
NAME=openvpn

# rate limit
RATE="5mbit"

# valid rate formats are taken from the linux tc command, and copied here:
#     bit or a bare number Bits per second
#     kbit   Kilobits per second
#     mbit   Megabits per second
#     gbit   Gigabits per second
#     tbit   Terabits per second
#     bps    Bytes per second
#     kbps   Kilobytes per second
#     mbps   Megabytes per second
#     gbps   Gigabytes per second
#     tbps   Terabytes per second


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
        -e RATE="$RATE" \
	-p 8888:8888/tcp \
	jdimpson/openvpn-client:latest
