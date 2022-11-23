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

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

tunctl -g 1000 -t tap1
tunctl -g 1000 -t tap2
tunctl -g 1000 -t tap3
tunctl -g 1000 -t tap4
tunctl -g 1000 -t tap5

ip addr add 192.168.7.101/32 broadcast 192.168.7.255 dev tap1
ip addr add 192.168.7.102/32 broadcast 192.168.7.255 dev tap2
ip addr add 192.168.7.103/32 broadcast 192.168.7.255 dev tap3
ip addr add 192.168.7.104/32 broadcast 192.168.7.255 dev tap4
ip addr add 192.168.7.105/32 broadcast 192.168.7.255 dev tap5

ip link set dev tap1 up
ip link set dev tap2 up
ip link set dev tap3 up
ip link set dev tap4 up
ip link set dev tap5 up

ip route add to 192.168.7.201/32 dev tap1
ip route add to 192.168.7.202/32 dev tap2
ip route add to 192.168.7.203/32 dev tap3
ip route add to 192.168.7.204/32 dev tap4
ip route add to 192.168.7.205/32 dev tap5

iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.101/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.102/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.103/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.104/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.105/32

iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.201/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.202/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.203/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.204/32
iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.205/32

echo 1 > /proc/sys/net/ipv4/ip_forward
echo 1 > /proc/sys/net/ipv4/conf/tap1/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/tap2/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/tap3/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/tap4/proxy_arp
echo 1 > /proc/sys/net/ipv4/conf/tap5/proxy_arp

iptables -P FORWARD ACCEPT
