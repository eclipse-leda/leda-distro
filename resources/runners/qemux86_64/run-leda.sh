#!/bin/bash
# /********************************************************************************
# * Copyright (c) 2022 Contributors to the Eclipse Foundation
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
# Run qemu with TAP network
#
# set -x 

USERID="-u $(id -u)"
GROUP="-g $(id -g)"
TUNCTL="sudo tunctl"
IFCONFIG="sudo ip"
IPTABLES="sudo iptables"
TAP=

function setupTap() {
    TAP=`$TUNCTL -b $GROUP 2>&1`
    n=$[ (`echo $TAP | sed 's/tap//'` * 2) + 1 ]
    $IFCONFIG addr add 192.168.7.$n/32 broadcast 192.168.7.255 dev $TAP
    $IFCONFIG link set dev $TAP up
    dest=$[ (`echo $TAP | sed 's/tap//'` * 2) + 2 ]
    $IFCONFIG route add to 192.168.7.$dest dev $TAP
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$n/32
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$dest/32
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/conf/$TAP/proxy_arp"
    $IPTABLES -P FORWARD ACCEPT
    echo "Set up TAP network interface: $TAP"
}

function teardownTap() {
    echo "Tearing down TAP network interface: $TAP"
    $TUNCTL -d $TAP
    $IFCONFIG link del $TAP
    n=$[ (`echo $TAP | sed 's/tap//'` * 2) + 1 ]
    dest=$[ (`echo $TAP | sed 's/tap//'` * 2) + 2 ]
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$n/32
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$dest/32
}

trap teardownTap EXIT

function askInstall() {
    local package=$1
    while true
    do
        echo "Do you wish to install $package using sudo?"
        select ync in "Yes" "No" "Cancel"; do
            case $ync in
                Yes )
                    sudo apt-get install -y $package;
                    return 1
                ;;
                No )
                    return 0
                ;;
                Cancel )
                    exit
                ;;
            esac
        done
    done
}

if ! command -v qemu-system-x86_64 &> /dev/null
then
    echo "Qemu not installed."
    askInstall "qemu-system-x86"
else
    echo "Qemu found."
fi

if ! command -v tunctl &> /dev/null
then
    echo "tunctl not installed."
    askInstall "uml-utilities"
else
    echo "tunctl found."
fi




setupTap

sudo qemu-system-x86_64 \
 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:02 \
 -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
 -object rng-random,filename=/dev/urandom,id=rng0 \
 -device virtio-rng-pci,rng=rng0 \
 -drive id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,if=virtio,format=qcow2 \
 -enable-kvm \
# -serial mon:stdio \
 -serial null \
 -serial mon:vc \
 -nographic \
 -object can-bus,id=canbus0 \
 -device kvaser_pci,canbus=canbus0 \
 -drive if=pflash,format=qcow2,file=ovmf.qcow2 \
 -cpu IvyBridge \
 -machine q35 \
 -smp 4 \
 -m 4G
 
