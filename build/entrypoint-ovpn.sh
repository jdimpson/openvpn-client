#!/bin/sh
CLIENT=/etc/openvpn/client.ovpn
OVERRIDES=/overrides.ovpn
NAMESERVER=8.8.8.8

ETH0=eth0
TUN0=tun0

if ! test -z "$NS"; then
	NAMESERVER="$NS";
fi
# tried to do this in Dockerfile, can't figure out why it got overridden by systemd
echo "Setting name server to $NAMESERVER";
rm /etc/resolv.conf
echo "nameserver $NAMESERVER" > /etc/resolv.conf

if ip link add dummy0 type dummy; then
	ip link delete dummy0;
else
	echo "Make sure you give this container NET_ADMIN capability" >&2;
	exit 5;
fi

GW=$(ip route | sed -ne '/default/{s/default via \([^ ][^ ]* dev [^ ]*\).*/\1/; p}');

ROUTING=
echo;
if test -z "$LOCALSUBNET"; then
	echo "You should set LOCALSUBNET if you want to connect to the proxy or enable NAT routing";
else
	echo "LOCALSUBNET is $LOCALSUBNET via $GW";
	if ip route add $LOCALSUBNET via $GW; then
		echo "You can connect to dockerhost:8888 for HTTPS_PROXY access (or whichever port you forwarded)"; 
	else
		ROUTING=1;
		echo "Detected that we are bridged to local subnet. Enabling NAT routing for $LOCALSUBNET";
		# NOTE: for this to work the container needs to be bridged to the physical network, e.g. via macvlan.
		iptables -A FORWARD -i $ETH0 -o $TUN0 -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -A FORWARD -i $TUN0 -o $ETH0 -m state --state RELATED,ESTABLISHED -j ACCEPT
		iptables -A FORWARD -i $ETH0 -o $TUN0 -s $LOCALSUBNET -d 0.0.0.0/0 -j ACCEPT
		iptables -t nat -A POSTROUTING -o $TUN0 -j MASQUERADE
	fi
fi

if ! test -e /dev/net/tun; then
	echo "Can't find /dev/net/tun, please map it in as a device" >&2;
	exit 3;
fi

if ! test -z "$OVPNCLIENT"; then
	CLIENT="$OVPNCLIENT";
fi

if ! test -r "$CLIENT"; then
	echo "Can't find client config file $CLIENT, please map in to /etc/openvpn/ and/or specify it in OVPNCLIENT" >&2;
	exit 1;
fi

if ! test -r "$OVERRIDES"; then 
	echo "Can't find override config file $OVERRIDES" >&2;
	exit 4;
fi

if ! test -z "$RATE"; then
	( sleep 10; echo; echo "Setting up rate limit using rate $RATE"; /tc.sh "$RATE"; ) &
else
	echo;
	echo "No rate-limiting in effect";
fi

echo;
if test -x /usr/bin/tinyproxy; then
	echo "Running tinyproxy";
	tinyproxy -d &
else
	echo "Tinyproxy not installed, skipping";
fi

# https://api.myip.com/
# https://ipinfo.io
# https://am.i.mullvad.net/json
if test -z "$IPINFOAPI"; then
	IPINFOAPI=https://ipinfo.io/
fi
if which jq; then
	JQ=jq;
else
	JQ=cat;
fi
( sleep 20; while true; do \
	echo; \
	date; \
	IP=$(ip addr show $ETH0 | awk '/inet / {print $2}' | sed -e 's#/.*##'); \
	test -z "$ROUTING" || echo "export https_proxy=http://$IP:8888/ for proxy access and use $IP as a routed gateway."; \
	test -z "$ROUTING" && echo "Forward a port from container host to $IP:8888 for proxy access."; \
	wget -q "$IPINFOAPI" -O- | $JQ ; echo; \
	sleep 3600; done ) &

echo "Changing directory to /etc/openvpn";
cd /etc/openvpn || exit 6;
echo "Starting up openvpn in client mode using configs $CLIENT and $OVERRIDES";
exec openvpn --config "$CLIENT" --config "$OVERRIDES";

# failed exec
echo "Error running openvpn --config $CLIENT --config $OVERRIDES;" >&2;
exit 2;
