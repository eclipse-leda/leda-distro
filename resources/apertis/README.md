# Running Leda Stack on Apertis


## Preparation of the image

1. Download the latest Apertis IoT image

```shell
wget https://images.apertis.org/release/v2023/v2023.0/amd64/iot/apertis_v2023-iot-amd64-uefi_v2023.0.img.gz
```

2. Run the image, e.g. in QEMU:

```shell
qemu-system-x86_64 \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1880-:1880,hostfwd=tcp::1883-:1883,hostfwd=tcp::8888-:8888,hostfwd=tcp::30555-:30555 \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -hda apertis_v2023-iot-amd64-uefi_v2023.0.img \
    -serial mon:stdio \
    -serial null \
    -serial mon:vc \
    -boot order=cd \
    -nographic \
    -enable-kvm \
    -object can-bus,id=canbus0 \
    -device kvaser_pci,canbus=canbus0 \
    -cpu IvyBridge \
    -drive if=pflash,format=qcow2,file=ovmf.qcow2 \
    -machine q35 \
    -smp 4 \
    -m 2G
```

3. Login as `user` with password `user`

4. Install the dependencies by following the *Eclipse Kanto - [Getting Started Guide](https://websites.eclipseprojects.io/kanto/docs/getting-started/install/)* 

   > Note: Some tools are not available on Apertis out of the box, hence the following steps will describe the differences to the Kanto guide.

7. Add the `development` Apertis repository and install `containerd` Debian package:

```shell
sudo $SHELL
echo "deb https://repositories.apertis.org/apertis/ v2023 development" >> /etc/apt/sources.list.d/apertis-development.list
apt update
apt-get install -y curl ca-certificates containerd
```

8. Install Kanto 

```shell
# Still in sudo shell
curl -fsSL -o kanto.deb https://github.com/eclipse-kanto/kanto/releases/download/v0.1.0-M2/kanto_0.1.0-M2_linux_x86_64.deb
apt -o Dpkg::Options::="--force-overwrite" install ./kanto.deb
```

9. Verify Kanto Container Management is running:

```shell
systemctl status container-management
sudo kanto-cm list
```

10. Edit the network configuration file `/etc/connman/main.conf`
    Add `veth` to the following line:

```shell
echo "NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-,veth" >> /etc/connman/main.conf
systemctl restart connman
```

```
# Before
# NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-

# After
NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-,veth
```

11. Configure IP Rules to allow network traffic in `/etc/iptables/rules.v4`
    > Note: Add these lines before the `REJECT` statements.
```
-A INPUT -i kanto-cm0 -j ACCEPT
-A FORWARD -i kanto-cm0 -j ACCEPT
-A FORWARD -o kanto-cm0 -j ACCEPT
```

12. Add the cgroup for systemd by creating a new file `/usr/lib/systemd/user/cgroup-systemd.service`

```
[Unit]
Description=Create cgroup mount for systemd
DefaultDependencies=no
#Before=sysinit.target
#After=local-fs.target

[Service]
Type=oneshot
ExecStartPre=/usr/bin/mkdir /sys/fs/cgroup/systemd
ExecStart=/usr/bin/mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/systemd

[Install]
WantedBy=sysinit.target
```

13. Install the Eclipse Leda SDV core containers

> Note: Leda is using a newer version of Kanto Container Management and kanto-auto-deployer to deploy containers using descriptor files.
  This feature is not yet available on Apertis v2023, hence the containers will be created manually.

14. Install Kuksa Databroker

```shell
sudo kanto-cm create --name databroker \
    --ports=30555:55555/tcp \
    ghcr.io/eclipse/kuksa.val/databroker:0.3.0

sudo kanto-cm start --name databroker

# Verify the container is up and running:
sudo kanto-cm list
```

15. Install Vehicle Update Manager from Leda Incubator

```shell
sudo kanto-cm create --name vum \
    --e=SELF_UPDATE_TIMEOUT=30m \
    --e=SELF_UPDATE_ENABLE_REBOOT=true \
    --e=THINGS_CONN_BROKER=tcp://mosquitto:1883 \
    --e=THINGS_FEATURES=ContainerOrchestrator \
    --mp="/proc:/proc:shared" \
    --hosts="mosquitto:host_ip" \
    ghcr.io/eclipse-leda/leda-contrib-vehicle-update-manager/vehicleupdatemanager:main-1d8dca55a755c4b3c7bc06eabfa06ad49e068a48

sudo kanto-cm start --name vum
```

16. Install Self Update Agent from Leda Incubator

```shell
sudo mkdir -p /data/selfupdates

sudo kanto-cm create --name sua \
    --mp="/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:shared" \
    --mp="/data/selfupdates:/RaucUpdate:rprivate" \
    --mp="/etc/os-release:/etc/os-release:rprivate" \
    --ports=30052:50052/tcp \
    --hosts="mosquitto:host_ip" \
    ghcr.io/eclipse-leda/leda-contrib-self-update-agent/self-update-agent:build-66

sudo kanto-cm start --name sua
```

17. Install the Cloud Connector from Leda Incubator

```shell
sudo mkdir -p /data/var/certificates

# Replace with your device certificates
sudo touch /data/var/certificates/device.crt
sudo touch /data/var/certificates/device.key

sudo kanto-cm create --name cloudconnector \
    --mp="/data/var/certificates/device.crt:/device.crt" \
    --mp="/data/var/certificates/device.key:/device.key" \
    --e=CERT_FILE=/device.crt \
    --e=KEY_FILE=/device.key \
    --e=LOCAL_ADDRESS=tcp://mosquitto:1883 \
    --e="LOG_FILE=" \
    --e=LOG_LEVEL=INFO \
    --e=CA_CERT_PATH=/app/iothub.crt \
    --e=MESSAGE_MAPPER_CONFIG=/app/message-mapper-config.json \
    --e=ALLOWED_LOCAL_TOPICS_LIST=cloudConnector/# \
    ghcr.io/eclipse-leda/leda-contrib-cloud-connector/cloudconnector:main-47c01227a620a3dbd85b66e177205c06c0f7a52e

sudo kanto-cm start --name cloudconnector
```

18. Install examples: Seat Service

```shell
sudo kanto-cm create --name seatservice \
    --e=BROKER_ADDR=databroker-host:30555 \
    --e=RUST_LOG=info \
    --e=vehicle_data_broker=info \
    --ports="30051:50051/tcp" \
    --hosts="databroker-host:host_ip" \
    ghcr.io/boschglobal/kuksa.val.services/seat_service:v0.3.0

sudo kanto-cm start --name seatservice
```

19. Install example: Kuksa DBC Feeder

```shell
sudo kanto-cm create --name feedercan \
    --e=VEHICLEDATABROKER_DAPR_APP_ID=databroker \
    --e=VDB_ADDRESS=databroker-host:30555 \
    --e=USECASE=databroker \
    --e=LOG_LEVEL=info \
    --e=databroker=info \
    --e=broker_client=info \
    --e=dbcfeeder=info \
    --hosts="databroker-host:host_ip" \
    ghcr.io/eclipse/kuksa.val.feeders/dbc2val:v0.1.1

sudo kanto-cm start --name feedercan
```

20. Install example: Kuksa HVAC Example

```shell
sudo kanto-cm create --name hvac \
    --e=VEHICLEDATABROKER_DAPR_APP_ID=databroker \
    --e=VDB_ADDRESS=databroker-host:30555 \
    --hosts="databroker-host:host_ip" \
    ghcr.io/eclipse/kuksa.val.services/hvac_service:v0.1.0

sudo kanto-cm start --name hvac
```
