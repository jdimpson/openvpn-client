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

#GW=$(ip route | sed -ne '/default/{s/default via \([^ ][^ ]*\) .*/\1/; p}')
GW=$(ip route | sed -ne '/default/{s/default via \([^ ][^ ]* dev [^ ]*\).*/\1/; p}');

if test -z "$LOCALSUBNET"; then
	echo "You should set LOCALSUBNET if you want to connect to the proxy or enable NAT routing";
else
	echo "LOCALSUBNET is $LOCALSUBNET via $GW";
	ip route add $LOCALSUBNET via $GW

	echo "Enabling NAT routing back to $LOCALSUBNET";
	# NOTE: for this to work, the container needs to be bridged to the physical network, e.g. via macvlan.
	# should we try to detect if that's the case? we could compare values of $LOCALSUBNET and $GW
	# also if it is the case, the addition of the static route to $LOCALSUBNET above is probably unnecessary
	iptables -A FORWARD -i $ETH0 -o $TUN0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $TUN0 -o $ETH0 -m state --state RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $ETH0 -o $TUN0 -s $LOCALSUBNET -d 0.0.0.0/0 -j ACCEPT
	iptables -t nat -A POSTROUTING -o $TUN0 -j MASQUERADE
fi

echo "Make sure you give this container NET_ADMIN capability";

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
	echo "Can't find override config file $OVERRIDES";
	exit 4;
fi

if test -x /usr/bin/tinyproxy; then
	echo "Running tinyproxy" >&2;
	tinyproxy -d &
else
	echo "Tinyproxy not installed, skipping" >&2;
fi

( sleep 30; while true; do date; wget -q https://ipinfo.io/ -O- ; echo; sleep 3600; done ) &

exec openvpn --config "$CLIENT" --config "$OVERRIDES";

# failed exec
echo "Error running openvpn --config $CLIENT --config $OVERRIDES;" >&2;
exit 2;
