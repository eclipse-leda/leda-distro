#!/bin/bash

# Required for Self Update Agent -> RAUC integration
mkdir -p /run/dbus/
dbus-daemon --system --nofork --nopidfile --print-address --address=unix:path=/var/run/dbus/system_bus_socket 2>&1 | logger &
mkdir -p /data/selfupdates

# Required by Cloud Connector
mkdir -p /data/var/certificates/
touch /data/var/certificates/device.crt
touch /data/var/certificates/device.key

# Required by Kanto Container Management
mkdir -p /run/mosquitto
chown mosquitto:mosquitto /run/mosquitto
mosquitto -c /etc/mosquitto/mosquitto.conf 2>&1 | logger &
containerd 2>&1 | logger &
container-management 2>&1 | logger &

mkdir -p /sys/fs/cgroup/kanto-cm/

until [ -S /var/run/container-management/container-management.sock ]
do
     echo "Waiting for Eclipse Kanto Container Management..."
     sleep 1
done

kanto-auto-deployer /var/containers/manifests/
kanto-auto-deployer /var/containers/manifests/examples
kantui
bash
