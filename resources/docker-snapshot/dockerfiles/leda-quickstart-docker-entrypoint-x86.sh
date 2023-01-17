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
    n=1
    $IFCONFIG addr add 192.168.7.$n/32 broadcast 192.168.7.255 dev $TAP
    $IFCONFIG link set dev $TAP up
    # leda-x86 is 192.168.8.2
    # leda-arm64 is 192.168.8.3
    dest=2
    $IFCONFIG route add to 192.168.7.$dest dev $TAP
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/conf/$TAP/proxy_arp"
    $IPTABLES -P FORWARD ACCEPT
    echo "Set up TAP network interface: $TAP"
}

function teardownTap() {
    echo "Tearing down TAP network interface: $TAP"
    $TUNCTL -d $TAP
    $IFCONFIG link del $TAP
    # leda-x86 is 192.168.8.2
    # leda-arm64 is 192.168.8.3
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
}

#
#-device virtio-net-pci,netdev=net0 \
# -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::1883-:1883 \
 #
#   -net nic,model=virtio \
#        -net user,hostfwd=tcp::8022-:22 \

startQemuUnprivileged() {
    qemu-system-x86_64 \
    -net nic,model=virtio \
    -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1883-:1883 \
 -object rng-random,filename=/dev/urandom,id=rng0 \
 -device virtio-rng-pci,rng=rng0 \
 -drive id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,if=virtio,format=qcow2 \
 -serial mon:stdio \
 -serial null \
 -serial mon:vc \
 -nographic \
 -object can-bus,id=canbus0 \
 -device kvaser_pci,canbus=canbus0 \
 -drive if=pflash,format=qcow2,file=ovmf.qcow2 \
 -cpu IvyBridge \
 -machine q35 \
 -smp 4 \
 -m 2G
}

startQemuPrivileged() {

    trap teardownTap EXIT

    setupTap

    # Forward network traffic for SSH to the QEMU Guest
    iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.7.2:22

    # Forward network traffic for SSH to the QEMU Guest
    iptables -t nat -A PREROUTING -p tcp --dport 1883 -j DNAT --to-destination 192.168.7.2:1883

    # Masquerade the IP Address of the sender, so that the packet will go back to the gateway
    iptables -t nat -A POSTROUTING -j MASQUERADE

    # Run the DHCP server
    mkdir -p /var/lib/dhcp/
    touch /var/lib/dhcp/dhcpd.leases
    /usr/sbin/dhcpd
    /usr/sbin/dnsmasq

    printf -v macaddr "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

    sudo qemu-system-x86_64 \
 -device virtio-net-pci,netdev=net0,mac=$macaddr \
 -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
 -object rng-random,filename=/dev/urandom,id=rng0 \
 -device virtio-rng-pci,rng=rng0 \
 -drive id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,if=virtio,format=qcow2 \
 -enable-kvm \
 -serial mon:stdio \
 -serial null \
 -serial mon:vc \
 -nographic \
 -object can-bus,id=canbus0 \
 -device kvaser_pci,canbus=canbus0 \
 -drive if=pflash,format=qcow2,file=ovmf.qcow2 \
 -cpu IvyBridge \
 -machine q35 \
 -smp 4 \
 -m 2G
}

PRIVILEGED=1

if [ $(id -u) != 0 ]; then
    echo "We're not uid 0, falling back to unprivileged mode."
    PRIVILEGED=0
fi

if [ ! -w /proc/sys/net/ipv4/ip_forward ]; then 
    echo "/proc/sys/net/ipv4/ip_forward is not writable for us, falling back to unprivileged mode."
    PRIVILEGED=0
fi

if [ "$PRIVILEGED" == 0 ]; then
    startQemuUnprivileged
else
    startQemuPrivileged
fi

