#!/bin/bash
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
set -e

echo "Eclipse Leda"
echo "running on $(cat /etc/issue)"
echo "running on $(cat /etc/os-release)"

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
echo "Core container deployment code: $?"
kanto-auto-deployer /var/containers/manifests/examples
echo "Example deployment code: $?"

if [ -t 0 ] ; then
    echo "(interactive shell. type 'exit' to quit the container)"
    kantui
    bash
else
    echo "(not interactive shell)"
    [ ! -z "$@" ] && /bin/bash -c "$@"
fi
