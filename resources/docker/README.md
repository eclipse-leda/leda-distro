# Eclipse Leda - Docker Builds

This repository contains a docker-compose file and Dockerfiles for running Eclipse Leda instances
and needed infrastructure within docker for testing and evaluation purposes.

Pre-Requisites:
- A recent Docker and Docker Compose Plugin version (compose file is using build secrets).
- A potent host machine, e.g 16 vCPU, 32 GB RAM

# Docker Compose - General Usage

Starting up Docker Compose:

    ./run-docker.sh

Shutting down Docker Compose:

    ./stop-docker.sh

## Building

The build configuration and the Dockerfiles will download the latest public release of the Eclipse Leda quickstart distribution,
install necessary dependencies for runtime and some configuration changes.

    docker compose build

*Note: For building outside of a GitHub Codespace, you may need to manually set and export the `GITHUB_TOKEN` environment variable to access the github repository.*

## Developer Shell

Developer Shell:

    docker compose run devshell

From there, you can log in to either Leda on QEMU x86-64, or log in to Leda on QEMU ARM-64.

    ssh leda-x86
    ssh leda-arm64

## Interacting with Eclipse Leda

1. Check the general system status

    sdv-health

### Device Provisioning

*Note: The device provisioning is work in progress.*

### Sending C2D Messages to a connected device

Use `send-message.sh` to send an Azure C2D Message via an IoT Hub to the device. This example script will trigger a Self Update bundle installation.

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

    mosquitto_sub -h localhost -p 1883 -t '#'

# Networking

You need to enable IP forwarding from Docker containers to make networking work.
The containers (leda-arm64, leda-x86) need to run with ``--privileged`` as they change iptables rules for proper forwarding of network packets.

https://docs.docker.com/network/bridge/#enable-forwarding-from-docker-containers-to-the-outside-world

    sudo sysctl net.ipv4.conf.all.forwarding=1
    sudo iptables -P FORWARD ACCEPT

Each Eclipse Leda instance (ARM64, x86_64) is running within a QEMU emulated network (192.168.7.2), which itself is contained
in a containerized network called `leda-network` (192.168.8.x).

The containers wrapping the QEMU instances will forward the following ports to the respective QEMU process:
- SSH on port 22
- Mosquitto on port 1883
- Kubernetes API on port 6433

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

# Troubleshooting

If login to Leda Docker DevShell does not work, or if you want to attach directly into the container running QEMU, you need to execute a one-off command shell in the running container:

    docker compose exec leda-x86 /bin/bash

When the building of the Docker containers fails as there is no access to the latest release artifacts or build artifacts, you may want to set the current GITHUB_REPOSITORY variable to your own build repository, before running the run-docker.sh script:

    export GITHUB_REPOSITORY="MyGithubOrg/my-leda-distro-fork"
    ./run-docker.sh

# Profiles

Profiles can be used to determine which containers (services) docker compose should be starting by default.
This is mostly used to have the `devshell` container not start up by default.
- `tools`: Contains docker containers which are not essential at runtime, must useful for testing and development purposes

# Metrics Dashboards

- Prometheus is used to collect data from the containers
- procexporter is used to monitor the QEMU instances (CPU + Memory)
- Grafana is used to visualize. Open http://localhost:3000/ to see dashboard
