#!/bin/sh
CLIENT=/etc/openvpn/client.ovpn
OVERRIDES=/overrides.ovpn
NAMESERVER=8.8.8.8

# tried to do this in Dockerfile, can't figure out why it got overridden by systemd
rm /etc/resolv.conf
echo "nameserver $NAMESERVER" > /etc/resolv.conf

#GW=$(ip route | sed -ne '/default/{s/default via \([^ ][^ ]*\) .*/\1/; p}')
GW=$(ip route | sed -ne '/default/{s/default via \([^ ][^ ]* dev [^ ]*\).*/\1/; p}');

if test -z "$LOCALSUBNET"; then
	echo "You should set LOCALSUBNET if you want to connect to the proxy";
else
	echo "LOCALSUBNET is $LOCALSUBNET via $GW";
	ip route add $LOCALSUBNET via $GW
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
