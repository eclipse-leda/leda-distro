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

function check() {
    command -v $1 >/dev/null && return 0
    type -P $1 >/dev/null&& return 0
    [ -f /usr/bin/$1 ] && return 0
    echo "ERROR: $1 missing"
    exit 1
}

echo "Eclipse Leda - Debian Package Installation Tester"

echo "- Checking packages, binaries and tools"
check containerd
check container-management
check sdv-help
check sdv-health
check sdv-provision
check sdv-kanto-ctl
check sdv-ctr-exec
check kantui
check kanto-auto-deployer

echo "- Starting containerd and container-management"
mosquitto &
sleep 1
mkdir /var/lib/containerd
mount -t tmpfs none /var/lib/containerd
containerd config default | sed 's/snapshotter = "overlayfs"/snapshotter = "native"/g' | tee /etc/containerd/config.toml
containerd &
sleep 1
container-management --cfg-file=/etc/container-management/config.json &
sleep 1
kanto-cm sysinfo

# Prepare container: cloud-connector
mkdir -p /data/var/certificates/
touch /data/var/certificates/device.crt
touch /data/var/certificates/device.key
touch /data/var/certificates/ca.key

# Prepare container: Fake folders and DBUS
mkdir -p /data/selfupdates
mkdir -p /var/run/dbus/
dbus-daemon --config-file=dbus-config.conf --print-address &

kanto-auto-deployer /var/containers/manifests/ || exit 1
kanto-cm list
echo "All checks succeeded."
