#!/bin/bash

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
containerd &
sleep 1
container-management --net-type=host --cfg-file=/etc/container-management/config.json &
sleep 1
kanto-cm sysinfo
kanto-auto-deployer /var/containers/manifests/ || exit 1

echo "All checks succeeded."