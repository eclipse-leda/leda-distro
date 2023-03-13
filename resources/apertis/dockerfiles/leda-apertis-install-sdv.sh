#!/bin/sh
# /********************************************************************************
# * Copyright (c) 2023 Contributors to the Eclipse Foundation
# *
# * See the NOTICE file(s) distributed with this work for additional
# * information regarding copyright ownership.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Apache License 2.0 which is available at
# * https://www.apache.org/licenses/LICENSE-2.0
# *
# * SPDX-License-Identifier: Apache-2.0
# ********************************************************************************/
#
# Install SDV Components on Apertis
#
#set -e

# Add the `development` Apertis repository and install `containerd` Debian package
echo "deb https://repositories.apertis.org/apertis/ v2023 development" >> /etc/apt/sources.list.d/apertis-development.list
apt update
apt-get install -y curl ca-certificates containerd

# Install Kanto 
curl -fsSL -o kanto.deb https://github.com/eclipse-kanto/kanto/releases/download/v0.1.0-M2/kanto_0.1.0-M2_linux_x86_64.deb
apt -o Dpkg::Options::="--force-overwrite" install ./kanto.deb

# Blacklist Kanto network interfaces from Connection Manager
# so that virtual ethernet interfaces are not used for default routes
echo "NetworkInterfaceBlacklist = vmnet,vboxnet,virbr,ifb,ve-,vb-,veth" >> /etc/connman/main.conf
systemctl restart connman

until systemctl is-active container-management
do
  echo "SDV Installer: Kanto Container Management not up yet, trying again..."
  sleep 1
done

# Kuksa Databroker
echo "SDV Installer: Kuksa Databroker"
kanto-cm create --name databroker \
    --ports=30555:55555/tcp \
    ghcr.io/eclipse/kuksa.val/databroker:0.3.0
kanto-cm start --name databroker

# Leda Incubator: Vehicle Update Manager
echo "SDV Installer: Vehicle Update Manager"
kanto-cm create --name vum \
    --e=SELF_UPDATE_TIMEOUT=30m \
    --e=SELF_UPDATE_ENABLE_REBOOT=true \
    --e=THINGS_CONN_BROKER=tcp://mosquitto:1883 \
    --e=THINGS_FEATURES=ContainerOrchestrator \
    --mp="/proc:/proc:shared" \
    --hosts="mosquitto:host_ip" \
    ghcr.io/eclipse-leda/leda-contrib-vehicle-update-manager/vehicleupdatemanager:main-1d8dca55a755c4b3c7bc06eabfa06ad49e068a48
kanto-cm start --name vum

# Leda Incubator: Self Update Agent
echo "SDV Installer: Self Update Agent"
sudo mkdir -p /data/selfupdates
sudo kanto-cm create --name sua \
    --mp="/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:shared" \
    --mp="/data/selfupdates:/RaucUpdate:rprivate" \
    --mp="/etc/os-release:/etc/os-release:rprivate" \
    --ports=30052:50052/tcp \
    --hosts="mosquitto:host_ip" \
    ghcr.io/eclipse-leda/leda-contrib-self-update-agent/self-update-agent:build-66
sudo kanto-cm start --name sua

# Leda Incubator: Cloud Connector
echo "SDV Installer: Cloud Connector (unconfigured)"
mkdir -p /data/var/certificates
# Replace with your device certificates
touch /data/var/certificates/device.crt
touch /data/var/certificates/device.key
kanto-cm create --name cloudconnector \
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
kanto-cm start --name cloudconnector

# Examples: Seat Service
echo "SDV Installer: Kuksa.VAL Seat Service Example"
kanto-cm create --name seatservice \
    --e=BROKER_ADDR=databroker-host:30555 \
    --e=RUST_LOG=info \
    --e=vehicle_data_broker=info \
    --ports="30051:50051/tcp" \
    --hosts="databroker-host:host_ip" \
    ghcr.io/boschglobal/kuksa.val.services/seat_service:v0.3.0
kanto-cm start --name seatservice

# Example: Kuksa DBC Feeder
echo "SDV Installer: Kuksa.VAL DBC CAN Feeder Example"
kanto-cm create --name feedercan \
    --e=VEHICLEDATABROKER_DAPR_APP_ID=databroker \
    --e=VDB_ADDRESS=databroker-host:30555 \
    --e=USECASE=databroker \
    --e=LOG_LEVEL=info \
    --e=databroker=info \
    --e=broker_client=info \
    --e=dbcfeeder=info \
    --hosts="databroker-host:host_ip" \
    ghcr.io/eclipse/kuksa.val.feeders/dbc2val:v0.1.1
kanto-cm start --name feedercan

# Example: Kuksa HVAC Example
echo "SDV Installer: Kuksa.VAL HVAC Example"
kanto-cm create --name hvac \
    --e=VEHICLEDATABROKER_DAPR_APP_ID=databroker \
    --e=VDB_ADDRESS=databroker-host:30555 \
    --hosts="databroker-host:host_ip" \
    ghcr.io/eclipse/kuksa.val.services/hvac_service:v0.1.0
kanto-cm start --name hvac

echo "SDV Installer done."
echo ""
echo "You may now login to Apertis as `user` with password `user`"
echo ""
