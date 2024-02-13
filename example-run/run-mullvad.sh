#!/bin/sh

# usage: ./run_mullvad.sh [two letter country code]  [listen port to forward to the proxy[

# to use this, you need to download your own mullvad openvpn config files, 
# unzip them, into the same folder as you run this script in. You may need 
# to modify them to use fully qualified file names as they appear in the 
# running container (e.g. in /etc/openvpn)
 
MVGW=au
LPORT=8888
LOCALSUBNET="192.168.1.0/24"

if ! test -z "$1";then
	MVGW="$1";
fi
if ! test -z "$2"; then
	LPORT="$2";
fi

FILE="mullvad_${MVGW}_all.conf";
CLIENT="/etc/openvpn/mullvad_config_linux/$FILE";

if ! test -r "mullvad_config_linux/$FILE"; then
	echo "Mullvad country $MVGW (mullvad_config_linux/$FILE) not found"; >&2;
	exit 1;
fi

NAME=openvpn-mullvad-$MVGW
docker run -it --rm \
	--name="$NAME" \
	--cap-add=NET_ADMIN \
 	--device=/dev/net/tun:/dev/net/tun \
	--mount type=bind,source="$(pwd)/",target="/etc/openvpn/" \
	-e OVPNCLIENT="$CLIENT" \
	-e LOCALSUBNET="$LOCALSUBNET" \
	-p "$LPORT:8888/tcp" \
	jdimpson/openvpn-client:latest


exit 0;

