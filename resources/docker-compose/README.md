# Eclipse Leda Docker Compose for Users

This is a docker compose setup which uses published container images from the ghcr.io container registry.
Building the images is not necessary.

## Usage

Starting the containers with:

    docker compose up --detach --wait

Log in to a development shell inside of the docker network:

    docker compose run devshell

Stopping the containers:

    docker compose down

## Docker Compose Services

Checking all containers are running or exited successfully:

    $ docker compose ps
    NAME                 COMMAND                  SERVICE              STATUS              PORTS
    leda-arm64           "/docker/leda-quicks…"   leda-arm64           running (healthy)   1883/tcp, 0.0.0.0:2002->2222/tcp, :::2002->2222/tcp, 0.0.0.0:9102->8888/tcp, :::9102->8888/tcp, 0.0.0.0:30556->30555/tcp, :::30556->30555/tcp
    leda-bundle-server   "/docker-entrypoint.…"   leda-bundle-server   running (healthy)   0.0.0.0:8080->80/tcp, :::8080->80/tcp
    leda-dns-proxy       "dnsmasq -k"             dns-proxy            running             53/tcp, 0.0.0.0:5353->53/udp, :::5353->53/udp
    leda-initializer     "/bin/sh -c /root/le…"   leda-initializer     exited (0)          
    leda-mqtt-broker     "/docker-entrypoint.…"   mqtt-broker          running (healthy)   0.0.0.0:1883->1883/tcp, :::1883->1883/tcp
    leda-x86             "/docker/leda-quicks…"   leda-x86             running (healthy)   1883/tcp, 0.0.0.0:30555->30555/tcp, :::30555->30555/tcp, 0.0.0.0:2001->2222/tcp, :::2001->2222/tcp, 0.0.0.0:9101->8888/tcp, :::9101->8888/tcp## Network setup

As the networking is complicated to set up with emulated network inside of qemu, forwarding it to the Docker network, the following explanation is helpful to understand networking better.

- All docker compose containers are attached to a network called `leda-bridge` and can see each other
- The qemu instances use a TAP network inside of each leda-quickstart-xxx container and do a NAT network translation to their own container
- The Docker internal DNS server is being used
- Only the exposed ports are forwarded from the docker container into the qemu process: mosquitto `1883`, ssh `2222` and kuksa.val databroker `30555`.

## Developer Shell

Developer Shell:

    docker compose run devshell

From there, you can log in to either Leda on QEMU x86-64, or log in to Leda on QEMU ARM-64.

    ssh leda-x86
    ssh leda-arm64

To run an additional terminal in the developer shell, execute this:

    docker compose exec devshell /bin/bash

## Interacting with Eclipse Leda

1. Check the general system status

    sdv-health

### Device Provisioning

1. Run the provisioning script:

    sdv-provision

2. Copy the fingerprints

3. Go to Azure IoT Hub, create a new device

4. Use the certificate's common name (CN) as Device Id - on Leda, this defaults to a part of the MAC Address

5. Select `X.509 Self-Signed` authentication type and enter both fingerprints

6. Click Save

### MQTT Broker Bridge

```mermaid
  graph LR;
      A["MQTT Container <br> on docker host <br> localhost:1883"] -- Bridge --> B[leda-x86:31883];
      A -- Bridge --> C[leda-arm64:31883];
      B-->B1[k3s <br> mosquitto service <br> leda-x86:1883];
      C-->C1[k3s <br> mosquitto service <br> leda-arm64:1883];
```

The Docker Compose setup will also start an Eclipse Mosquitto message broker as a bridge to both Leda instances.
This allows a user or developer to monitor messages sent by or received by both virtual devices.

Connect your MQTT client to `mqtt-broker.leda-network` by using the exposed port 1883 on the host:

    mosquitto_sub -h localhost -p 1883 -t '#' -v

# Networking

You need to enable IP forwarding from Docker containers to make networking work.
The containers (leda-arm64, leda-x86) need to run with ``--privileged`` as they change iptables rules for proper forwarding of network packets.

https://docs.docker.com/network/bridge/#enable-forwarding-from-docker-containers-to-the-outside-world

    sudo sysctl net.ipv4.conf.all.forwarding=1
    sudo iptables -P FORWARD ACCEPT

Each Eclipse Leda instance (ARM64, x86_64) is running within a QEMU emulated network (192.168.7.2), which itself is contained
in a containerized network called `leda-network` (192.168.8.x).

The containers wrapping the QEMU instances will forward the following ports to the respective QEMU process:
- SSH on port 2222
- Mosquitto on port 1883

## DHCP and DNS setup

Each Leda-QEMU container is running a local DHCP on the `tap0` network interface and listens for DHCP requests by the Leda Distro running inside of QEMU.
The DHCP server will respond with the same IP address (`192.168.7.2`) to the request from QEMU.

The DHCP response contains a DNS nameserver pointing to the `dns-proxy.leda-network` (`192.168.8.14`) IP, which in turn forwards to Docker's internal `127.0.0.11` nameserver.
This allows the QEMU guests to resolve Docker Compose Services by their service name, e.g. `leda-bundle-server.leda-network`.

## Volumes

The `/root` path inside of the Leda containers is mounted as a volume and contains the raw disk image and runner scripts for the QEMU Leda distribution.
Changes on the QEMU filesystem are made persistent on a copy of the QCOW2 disk image, so that restarting the device will keep any changes.

To reset to the original state, delete the respective docker volumes and restart the containers:

    docker compose down
    docker compose rm --force --stop --volumes
    docker volume rm leda-arm64
    docker volume rm leda-x86

# Profiles

Profiles can be used to determine which containers (services) docker compose should be starting by default.
This is mostly used to have the `devshell` container not start up by default.
- `tools`: Contains docker containers which are not essential at runtime, must useful for testing and development purposes
