# Eclipse Leda - Plain Docker Setup

When not using Docker Compose, the Eclipse Leda quickstart images can be started individually with plain Docker.

# Usage

    docker run -it --rm -p 2222:2222 -p 1883:1883 ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest

Then, you can use `ssh -p 2222 root@localhost` to connect to the qemu guest, or use `localhost:1883` with an MQTT client to connect to the message broker.

## Privileged

When run with as a privileged container, qemu will try to set up a TAP network and use KVM acceleration. Network and CPU will be faster.
    
    docker run -it --privileged ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest

To also expose the ports, so that you can connect using ssh or mqtt, add the port mappings:

    docker run -it --privileged -p 2222:2222 -p 1883:1883 --device=/dev/kvm:/dev/kvm --device=/dev/net/tun:/dev/net/tun ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest


