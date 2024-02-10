FROM alpine:latest
ENV LOCALSUBNET= \
    OVPNCLIENT=
RUN apk add openvpn && apk add tinyproxy && sed -e '/^Allow/ s/^/#/' -i /etc/tinyproxy/tinyproxy.conf && apk add curl iptables speedtest-cli
COPY ovpn-entrypoint.sh /ovpn-entrypoint.sh
RUN chmod a+x /ovpn-entrypoint.sh
COPY overrides.ovpn /overrides.ovpn
RUN echo "rm /etc/resolv.conf && nameserver 8.8.8.8 > /etc/resolv.conf"
EXPOSE 8888/tcp
#CMD /ovpn-entrypoint.sh
#ENTRYPOINT /ovpn-entrypoint.sh
ENTRYPOINT ["/ovpn-entrypoint.sh"]
