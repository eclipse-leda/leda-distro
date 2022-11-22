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
# Run a DHCP service for the TAP networks
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

touch dhcpc.leases
sudo dhcpd -4 -cf dhcp.conf -f -d -lf dhcpc.leases -pf dhcp.pid tap1 tap2 tap3 tap4 tap5
