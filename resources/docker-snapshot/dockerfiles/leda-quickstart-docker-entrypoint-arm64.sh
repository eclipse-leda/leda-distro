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
    echo "Set up TAP network interface: $TAP"
}

function teardownTap() {
    echo "Tearing down TAP network interface: $TAP"
    $TUNCTL -d $TAP
    $IFCONFIG link del $TAP
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    $IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
}

startQemuUnprivileged() {
    qemu-system-aarch64 \
        -device virtio-net-device,netdev=net0 \
        -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::1883-:1883,hostfwd=tcp::8888-:8888,hostfwd=tcp::30555-:30555 \
        -object rng-random,filename=/dev/urandom,id=rng0 \
        -device virtio-rng-pci,rng=rng0 \
        -drive id=disk0,file=sdv-image-all-qemuarm64.wic.qcow2,if=none,format=qcow2 \
        -device virtio-blk-device,drive=disk0 \
        -device qemu-xhci \
        -device usb-tablet \
        -device usb-kbd \
        -serial mon:stdio \
        -serial null \
        -serial mon:vc \
        -nographic \
        -object can-bus,id=canbus0 \
        -device kvaser_pci,canbus=canbus0 \
        -machine virt \
        -cpu cortex-a57 \
        -smp 4 \
        -m 2G \
        -device virtio-gpu-pci \
        -bios u-boot.bin
}

startQemuPrivileged() {

    trap teardownTap EXIT

    setupTap

    # Forward network traffic for SSH to the QEMU Guest
    iptables -t nat -A PREROUTING -p tcp --dport 2222 -j DNAT --to-destination 192.168.7.2:22

    # Forward network traffic for SSH to the QEMU Guest
    iptables -t nat -A PREROUTING -p tcp --dport 1883 -j DNAT --to-destination 192.168.7.2:1883

    # Forward network traffic for cAdvisor on the Leda Guest
    iptables -t nat -A PREROUTING -p tcp --dport 8888 -j DNAT --to-destination 192.168.7.2:8888

    # Forward network traffic for Kuksa Databroker on the Leda Guest
    iptables -t nat -A PREROUTING -p tcp --dport 30555 -j DNAT --to-destination 192.168.7.2:30555

    # Masquerade the IP Address of the sender, so that the packet will go back to the gateway
    iptables -t nat -A POSTROUTING -j MASQUERADE

    # Run the DHCP server
    mkdir -p /var/lib/dhcp/
    touch /var/lib/dhcp/dhcpd.leases
    /usr/sbin/dhcpd
    sudo /usr/sbin/dnsmasq

    printf -v macaddr "52:54:%02x:%02x:%02x:%02x" $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff )) $(( $RANDOM & 0xff)) $(( $RANDOM & 0xff ))

    qemu-system-aarch64 \
    -device virtio-net-device,netdev=net0,mac=$macaddr \
    -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -drive id=disk0,file=sdv-image-all-qemuarm64.wic.qcow2,if=none,format=qcow2 \
    -device virtio-blk-device,drive=disk0 \
    -device qemu-xhci \
    -device usb-tablet \
    -device usb-kbd \
    -serial mon:stdio \
    -serial null \
    -nographic \
    -object can-bus,id=canbus0 \
    -device kvaser_pci,canbus=canbus0 \
    -machine virt \
    -cpu cortex-a57 \
    -smp 4 \
    -m 2G \
    -serial mon:vc \
    -device virtio-gpu-pci \
    -bios u-boot.bin
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