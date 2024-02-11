#!/bin/sh

IMAGE='jdimpson/openvpn-client';

if docker images | grep -q "$IMAGE"; then
	docker image rm "$IMAGE";
fi

docker build . -t "$IMAGE"
