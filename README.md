# openvpn-client
Simple project to provide OpenVPN client functionality in a container. This project is intended to be a learning tool for myself, to provide a motivation for digging into how to do Docker/Container networking, and sharpen my CI/CD skills.

If you are looking for a fully featured and more production friendly OpenVPN (and Wireguard) VPN client, check out [Gluetun](https://github.com/qdm12/gluetun). I've been using it as a model and resource as I figure out my way around Docker networking. I have no intention of supporting specific VPN vendor services, nor am I going to worry about too much stuff like DNS information leaking, whereas gluetun does.

## Example invocation

Make sure your OpenVPN client configuration file is called client.ovpn, and is present in the current directory.
```
docker run -it --rm --name="openvpn-client" --cap-add=NET_ADMIN --device=/dev/net/tun:/dev/net/tun --mount type=bind,source="$(pwd)/client.ovpn:/etc/openvpn/client.ovpn" -e LOCALSUBNET=192.168.69.0/24 -p 9999:8888/tcp jdimpson/openvpn-client:latest
```
(Hopefully I've figured out how to upload a container to docker hub or ghcr by the time you read this. If not, building it youself doesn't require anything more than a docker installation.)

There are other examples in the [example-run](example-run) folder.


## Functions supported
- [OpenVPN](https://openvpn.net/) client
    - Configured by giving you access to `/etc/openvpn/` to place whatever files are needed to connect to your OpenVPN service.
    - The simplest approach is map your config file in like this: `--mount type=bind,source="$(pwd)/<config file>",target="/etc/openvpn/client.ovpn"`
    - But if your OpenVPN client config consists of more than a single file, you should do something like this: `--mount type=bind,source="$(pwd)/",target="/etc/openvpn/"`
    - And either make sure your client config file is called `/etc/openvpn/client.ovpn`
    - Or set environment variable `OVPNCLIENT` to whatever file you is your client config, e.g. `-e OVPNCLIENT=/etc/openvpn/my_config.ovpn`
    - See [run.sh](example-run/run.sh) as an example of basic usage-- by default it requires a config file called `myclient.ovpn`.
- [tinyproxy](http://tinyproxy.github.io/) HTTP proxy
    - Listening on internal port 8888, mappable to any port on the container host, e.g. `-p 9999:8888/tcp`
    - Set environmental varable `LOCALSUBNET` to the LAN subnet where you container host is running, so that the proxy can talk to other devices on your local LAN, e.g. `-e LOCALSUBNET=192.168.68.0/24`
    - Then on any device on your local LAN, set the appropriate `https_proxy` environment variable or web browser proxy setting to `http://<your docker host name or IP>:8888/` (or whatever port you mapped to 8888 of the container)
    - e.g. `http_proxy=http://<docker host name or ip>:8888/ curl http://ipinfo.io/`
    - See [http_proxy.sh-example](example-run/http_proxy.sh-example) as an example of how to set environment variables to use the proxy (and thus the VPN).
    - See [ssh_config-example](example-run/ssh_config-example) as an example of how to set up an SSH client to use the proxy (and thus the VPN)
- Use as a routable gateway for other containers 
    - Make sure you give your running OpenVPN client container instance a name, e.g. `--name=openvpn`
    - Then start another container, using `--network=container:openvpn` to connect their network namespaces together. The secondary container(s) will use the routing table of the `openvpn` container, as managed by OpenVPN client.
    - See [curl-container-network.sh](example-run/curl-container-network.sh) as an example of how to cause other containers to use the network created by the openvpn-client container.
    - Similarly, use `network_mode=service:openvpn` or `network_mode=container:openvpn` if you are using docker compose.
- Provide VPNed command line webclients
    - Connect into the running container to run `wget`, `curl`, `tcpdump`, or `speedtest-cli`
    - e.g. on your docker host, run `docker exec -it openvpn curl https://ipinfo.io/`
- Use as a routable gateway for devices on your LAN!!!1
    - So you could set it as a route (default or otherwise) for other physical devices on your LAN and use your VPNs in the manner they are generally intended for.
    - Two ways:
        - See [run-host.sh](example-run/run-host.sh) for how to cause your docker host to have its default route changed so that all traffic goes over the VPN
            - (almost certainly not what you want if there are many users and/or many different services on your docker host, but useful if your docker host is intended to only be a router or some other other kind of network appliance)
        - See [run-macvlan.sh](example-run/run-macvlan.sh) for how to make your Openvpn-client container have it's own IP address on your local network, suitable to treat as a router. Trivially easy to convert to use layer 2 ipvlan rather than macvlan.
    - And once your container has become a valid router on your network, you have to point other systems at it so it can route for them. 
        - You can manually change their default gateway or add new static route(s) 
        - or on Linux systems, you can create an alternate gateway routing table that will only be applied to selected process. 
            - Run [altgw-setup.sh-example](example-run/altgw-setup.sh-example), then
            - Write the process ID of the program to `/sys/fs/cgroup/altgw/cgroup.procs` 
            - The easiest way to do that is start a new shell and run this command: `echo $$ | sudo tess /sys/fs/cgroup/altgw/cgroup.proc`
            - Now any program you run from that shell will utilize the new alternative gateway, as they will inherit the route of the shell. (Although not if you run them via sudo, which will break the inheritance.)
- Perform rate limiting.
    - Set the environment variable RATE in your docker run / docker compose command to establish a rate limit applied to both incoming and outgoing data.
    - See [run-ratelimit.sh](example-run/run-ratelimit.sh).
    - This uses the `tc` command and a relatively simple classification logic which gets applied to all packet traffic transmitted and received on the `eth0` interface. Alternatively you can run your own tc commands if you wish using a volume and a `docker exec` command.

    
## Requirements
- Your container needs the NET_ADMIN capability, e.g. `--cap-add=NET_ADMIN`
- And it needs access to the tun device, e.g. `--device=/dev/net/tun:/dev/net/tun`
- There are some limitations when running OpenVPN in a container. So there are overriding OpenVPN configuration parameters in `/overrides.ovpn`. The principle restriction one is that I haven't figured out how to support IPv6 yet.

## Building
```
git clone https://github.com/jdimpson/openvpn-client/
cd openvpn-client
docker build . -t jdimpson/openvpn-client
```
Then run as above.
