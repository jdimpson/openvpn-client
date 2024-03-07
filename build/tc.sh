#!/bin/sh

RATE="$1";
if test -z "$RATE"; then
	echo "Using default rate of 1mbit" >&2;
	RATE="1mbit";
fi

# from https://serverfault.com/questions/701194/limit-throttle-per-user-openvpn-bandwidth-using-tc?rq=1

# Make sure queueing discipline is enabled.
DEV=eth0
tc qdisc add dev $DEV root handle 1: htb 
tc qdisc add dev $DEV handle ffff: ingress 

# downrate: from here to distant end
# uprate: from distant end to here 
downrate="$RATE"
uprate="$RATE"
classid=10
ip=0.0.0.0/0

# Limit traffic from here to there
tc class add dev $DEV parent 1: classid 1:$classid htb rate $downrate
tc filter add dev $DEV protocol all parent 1:0 prio 1 u32 match ip dst $ip flowid 1:$classid

# Limit traffic from there to here
tc filter add dev $DEV parent ffff: protocol all prio 1 u32 match ip src $ip police rate $uprate burst 80k drop flowid :$classid

