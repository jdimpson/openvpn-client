#!/bin/bash

if test $# -lt 1; then
	set -- "https://ipinfo.io/";
fi

# This script is intended to work with one of the run.sh examples.

# this should be set to whatever you named your running container.
# i use "openvpn" in all the other run.sh examples.
OVPN_CONTAINER_NAME="openvpn"

if ! docker run -it --rm --network=container:"$OVPN_CONTAINER_NAME" curlimages/curl $*; then
	echo "Failed to run curlimages/curl container. Either that container couldn't be found," >&2;
	echo "Or the openvpn-client container named $OVPN_CONTAINER_NAME is not running. " >&2;
	echo "This script is intended to work with one of the run.sh examples." >&2;
	exit 1;
fi
exit 0;
