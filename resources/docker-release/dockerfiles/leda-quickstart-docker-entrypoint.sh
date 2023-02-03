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

# Forward network traffic for SSH to the QEMU Guest
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.7.2:22

# Forward network traffic for SSH to the QEMU Guest
iptables -t nat -A PREROUTING -p tcp --dport 31883 -j DNAT --to-destination 192.168.7.2:31883

# Forward network traffic for Prometheus Node Exporter to the QEMU Guest
iptables -t nat -A PREROUTING -p tcp --dport 30100 -j DNAT --to-destination 192.168.7.2:30100

# Forward Kubernetes Server API Port
iptables -t nat -A PREROUTING -p tcp --dport 6433 -j DNAT --to-destination 192.168.7.2:6443

# Masquerade the IP Address of the sender, so that the packet will go back to the gateway
iptables -t nat -A POSTROUTING -j MASQUERADE

./run-leda.sh