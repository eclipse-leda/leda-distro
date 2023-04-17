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
# Run qemu with TAP network
#
# set -x 

DISK_IMAGE_FILE="apertis.qcow2"

echo "Entry: Setup..."

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
    dest=2
    $IFCONFIG route add to 192.168.7.$dest dev $TAP
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    $IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/conf/$TAP/proxy_arp"
    $IPTABLES -P FORWARD ACCEPT
    echo "Entry: Set up TAP network interface: $TAP"
}

function teardownTap() {
    echo "Entry: Tearing down TAP network interface: $TAP"
    $TUNCTL -d $TAP
    $IFCONFIG link del $TAP
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
}

startQemuUnprivileged() {
    echo "Entry: Starting QEMU in unprivileged mode"

    qemu-system-x86_64 \
        -net nic,model=virtio \
        -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1880-:1880,hostfwd=tcp::1883-:1883,hostfwd=tcp::8888-:8888,hostfwd=tcp::30555-:30555 \
        -object rng-random,filename=/dev/urandom,id=rng0 \
        -device virtio-rng-pci,rng=rng0 \
        -drive id=hd,file=${DISK_IMAGE_FILE},if=virtio,format=qcow2 \
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
    echo "Entry: Starting QEMU in privileged mode"

    trap teardownTap EXIT

    setupTap

    # Forward network traffic for SSH to the QEMU Guest
    iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.7.2:22

    # Forward network traffic for SSH to the QEMU Guest
    # eth0 -> docker-internal network (172.x.x.x)
    iptables -t nat -A PREROUTING -j DNAT -i eth0 -p tcp --to-destination 192.168.7.2
    # eth1 -> leda-network (192.168.8.x)
    iptables -t nat -A PREROUTING -j DNAT -i eth1 -p tcp --to-destination 192.168.7.2

    # Masquerade the IP Address of the sender, so that the packet will go back to the gateway
    iptables -t nat -A POSTROUTING -j MASQUERADE

    # Run the DHCP server
    mkdir -p /var/lib/dhcp/
    touch /var/lib/dhcp/dhcpd.leases
    /usr/sbin/dhcpd
    sudo /usr/sbin/dnsmasq

    printf -v macaddr "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

    echo "Entry: Randomized MAC Address: ${macaddr}"

    sudo qemu-system-x86_64 \
 -device virtio-net-pci,netdev=net0,mac=$macaddr \
 -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
 -object rng-random,filename=/dev/urandom,id=rng0 \
 -device virtio-rng-pci,rng=rng0 \
 -drive id=hd,file=${DISK_IMAGE_FILE},if=virtio,format=qcow2 \
 -boot order=d,strict=on,menu=on \
 -serial mon:stdio \
 -serial null \
 -serial mon:vc \
 -nographic \
 -object can-bus,id=canbus0 \
 -device kvaser_pci,canbus=canbus0 \
 -drive if=pflash,readonly=on,format=qcow2,file=ovmf.code.qcow2 \
 -drive if=pflash,format=qcow2,file=ovmf.vars.qcow2 \
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

echo "Entry: Checking QEMU Version..."
qemu-system-x86_64 -version

echo "Entry: Starting SDV Installer in background..."
/docker/leda-apertis-bootstrapper.sh &

echo "Entry: Starting QEMU with Apertis image..."
if [ "$PRIVILEGED" == 0 ]; then
    startQemuUnprivileged
else
    startQemuPrivileged
fi