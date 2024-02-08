# openvpn-client
Simple project to provide OpenVPN client functionality in a container. This project is intended to be a learning tool for myself, to provide a motivation for digging into how to do Docker/Container networking, and sharpen my CI/CD skills.

If you are looking for a fully featured and more production friendly OpenVPN (and Wireguard) VPN client, check out [Gluetun](https://github.com/qdm12/gluetun). I've been using it as a model and resource as I figure out my way around Docker networking. I have no intention of supporting specific VPN vendor services, nor am I going to worry about too much stuff like DNS information leaking, whereas gluetun does.

## Example invocation

Make sure your OpenVPN client configuration file is called client.ovpn, and is present in the current directory.
```
docker run -it --rm --name="openvpn-client" --cap-add=NET_ADMIN --device=/dev/net/tun:/dev/net/tun --mount type=bind,source="$(pwd)/client.ovpn:/etc/openvpn/client.ovpn" -e LOCALSUBNET=192.168.69.0/24 -p 9999:8888/tcp jdimpson/openvpn-client:latest
```
(Hopefully I've figured out how to upload a container to docker hub or ghcr by the time you read this. If not, building it youself doesn't require anything more than a docker installation.)


## Functions supported
- [OpenVPN](https://openvpn.net/) client
    - Configured by giving you access to `/etc/openvpn/` to place whatever files are needed to connect to your OpenVPN service.
    - The simplest approach is map your config file in like this: `--mount type=bind,source="$(pwd)/<config file>",target="/etc/openvpn/client.ovpn"`
    - But if your OpenVPN client config consists of more than a single file, you should do something like this: `--mount type=bind,source="$(pwd)/",target="/etc/openvpn/"`
    - And either make sure your client config file is called `/etc/openvpn/client.ovpn`
    - Or set environment variable `OVPNCLIENT` to whatever file you is your client config, e.g. `-e OVPNCLIENT=/etc/openvpn/my_config.ovpn`
- [tinyproxy](http://tinyproxy.github.io/) HTTP proxy
    - Listening on internal port 8888, mappable to any port on the container host, e.g. `-p 9999:8888/tcp`
    - Set environmental varable `LOCALSUBNET` to the LAN subnet where you container host is running, so that the proxy can talk to other devices on your local LAN, e.g. `-e LOCALSUBNET=192.168.68.0/24`
    - Then on any device on your local LAN, set the appropriate `https_proxy` environment variable or web browser proxy setting to `http://<your docker host name or IP>:8888/` (or whatever port you mapped to 8888 of the container)
    - e.g. `http_proxy=http://<docker host name or ip>:8888/ curl http://ipinfo.io/`
- Use as a routable gateway for other containers 
    - Make sure you give your running OpenVPN client container instance a name, e.g. `--name=openvpn`
    - Then start another container, using `--network=container:openvpn` to connect their network namespaces together. The secondary container(s) will use the routing table of the `openvpn` container, as managed by OpenVPN client.
    - Or `network_mode=service:openvpn` or `network_mode=container:openvpn` if you are using docker compose.
- Provide VPNed command line webclients
    - Connect into the running container to run `wget` or `curl`
    - e.g. on your docker host, run `docker exec -it openvpn curl https://ipinfo.io/`
- Use as a routable gateway for devices on your LAN!!!1
    - *COMING SOON (MAYBE)*
    - So you could set it as a route (default or otherwise) for other physical devices on your LAN and use your VPNs in the manner they are generally intended for.
    
## Requirements
- Your container needs the NET_ADMIN capability, e.g. --cap-add=NET_ADMIN
- And it needs access to the tun device, e.g. --device=/dev/net/tun:/dev/net/tun
- There are some limitations when running OpenVPN in a container. So there are overriding OpenVPN configuration parameters in `/overrides.ovpn`. The principle restriction one is that I haven't figured out how to support IPv6 yet.

## Building
```
git clone https://github.com/jdimpson/openvpn-client/
cd openvpn-client
docker build . -t jdimpson/openvpn-client
```
Then run as above.
