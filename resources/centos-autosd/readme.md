# Eclipse Leda on Red Hat In-Vehicle OS (CentOS AutoSD)

Start point: https://sig.centos.org/automotive/#automotive-stream-distribution

# Building a Docker Container with QEMU running CentOS AutoSD binaries

Goal: Create a docker container with QEMU to run CentOS AutoSD binary images.

## Which image to use?

As we need SSH and package manager, to play around, we're using the "QA" image:

- Ostree-based qemu images built for our own QA/testing, for x86_64 and aarch64. It is based on the minimal image with some extra packages such as: SSH, beaker, rsync, sudo, wget, time, nfs-utils, git, jq. These images are:

Image name: `auto-osbuild-qemu-cs9-qa-ostree-x86_64`
Image size: ~400MB

https://autosd.sig.centos.org/AutoSD-9/nightly/sample-images/auto-osbuild-qemu-cs9-qa-ostree-x86_64-946743607.247784c5.qcow2.xz

Note: The minimal image would be around 180MB, but is missing SSH and package manager.

Build:

```shell
./build-docker.sh
```

## How to run CentOS

See https://sigs.centos.org/automotive/building/autosd_qemu/

```shell
./run-docker.sh
```
Login with "root" and "password"

## Deploying Leda Edge Stack components

### Eclipse Kuksa.VAL Databroker

```shell
# Kuksa.VAL Databroker for Vehicle Signal Abstraction
podman run --network host --detach --name databroker ghcr.io/eclipse/kuksa.val/databroker:0.3.0

# Eclipse Mosquitto (MQTT Broker)
podman run --network host --detach --name mosquitto docker.io/library/eclipse-mosquitto:latest

# Leda Self Update Agent
mkdir -p /data/selfupdates
chcon -Rt svirt_sandbox_file_t /var/run/dbus/system_bus_socket
podman run --network host --add-host "mosquitto:127.0.0.1" --detach --name sua --mount type=bind,src=/var/run/dbus/system_bus_socket,target=/var/run/dbus/system_bus_socket --mount type=bind,src=/data/selfupdates,target=/data/selfupdates --mount type=bind,src=/etc/os-release,target=/etc/os-release ghcr.io/eclipse-leda/leda-contrib-self-update-agent/self-update-agent:build-177
```

## Working with podman

Status: `podman ps`
Logs: `podman logs <container_id>`

Clean up:
```shell
podman stop --all
podman rm --all
```

## Deploying examples

```shell
podman run --detach --network host --env "VDB_ADDRESS=localhost:55555" --env "USECASE=databroker" --env "dbcfeeder=info" --env "LOG_LEVEL=info" --rm ghcr.io/eclipse/kuksa.val.feeders/dbc2val:v0.1.1

podman run --network host --env "VDB_ADDRESS=localhost:55555" --env "USECASE=databroker" ghcr.io/eclipse/kuksa.val.services/hvac_service:v0.1.0

podman run --network host --env "BROKER_ADDR=localhost:55555" ghcr.io/boschglobal/kuksa.val.services/seat_service:v0.3.0

podman run --network host --env "SDV_SEATSERVICE_ADDRESS=grpc://seatservice-example:50051" --env "SDV_VEHICLEDATABROKER_ADDRESS=grpc://databroker:55555" --env "SDV_MQTT_ADDRESS=mqtt://mosquitto:1883" --env "SDV_MIDDLEWARE_TYPE=native" ghcr.io/eclipse-leda/leda-example-applications/seatadjuster-app:latest

podman run --detach --network host --env "DATABROKER_ADDRESS=localhost:55555" ghcr.io/eclipse-leda/leda-example-applications/leda-example-carsim:v0.0.1
podman run --detach --network host --env "DATABROKER_ADDRESS=localhost:55555" ghcr.io/eclipse-leda/leda-example-applications/leda-example-driversim:v0.0.1
```

## Using Kuksa.VAL Databroker CLI

Run the Kuksa.VAL Databroker CLI as a container:

```shell
podman run --network host -it --rm --env "RUST_BACKTRACE=1" ghcr.io/eclipse/kuksa.val/databroker-cli:0.4
```

## Building and Customizing AutoSD

See https://sigs.centos.org/automotive/building/

## Installing Eclipse Kanto
ls -al

Inside RHIVOL prompt, get the Kanto RPM package:

wget https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/glibc-2.34-72.el9.i686.rpm
wget https://rpmfind.net/linux/centos-stream/9-stream/BaseOS/x86_64/os/Packages/libgcc-11.4.1-2.1.el9.i686.rpm

wget https://rpmfind.net/linux/fedora/linux/releases/38/Everything/x86_64/os/Packages/c/c-ares-1.19.0-1.fc38.i686.rpm
wget https://rpmfind.net/linux/epel/9/Everything/x86_64/Packages/m/mosquitto-2.0.15-1.el9.x86_64.rpm

wget https://rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/c/containerd-1.6.19-2.fc39.x86_64.rpm

wget https://rpmfind.net/linux/fedora/linux/development/rawhide/Everything/x86_64/os/Packages/m/mosquitto-2.0.15-3.fc39.x86_64.rpm


wget https://github.com/eclipse-kanto/kanto/releases/download/v0.1.0-M3/kanto_0.1.0-M3_linux_x86_64.rpm
rpm -i kanto_0.1.0-M3_linux_x86_64.rpm

