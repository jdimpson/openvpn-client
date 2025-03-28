FROM alpine:latest
ENV LOCALSUBNET= \
    OVPNCLIENT= \
    RATE=
RUN apk add --update openvpn && apk add tinyproxy bash && sed -e '/^Allow/ s/^/#/' -i /etc/tinyproxy/tinyproxy.conf && apk add curl iptables speedtest-cli tcpdump iproute2-tc
COPY tc.sh /tc.sh
RUN chmod a+x /tc.sh
COPY entrypoint-ovpn.sh /entrypoint-ovpn.sh
RUN chmod a+x /entrypoint-ovpn.sh
COPY overrides.ovpn /overrides.ovpn
RUN echo "rm /etc/resolv.conf && nameserver 8.8.8.8 > /etc/resolv.conf"
EXPOSE 8888/tcp
ENTRYPOINT ["/entrypoint-ovpn.sh"]
