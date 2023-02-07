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
echo "Welcome to Eclipse Leda Docker DevShell"
echo ""
echo "Initializing environment..."
mkdir -p ~/.ssh/
echo "- SSH Hosts Configuration in ~/.ssh/config"
echo "- Adding SSH fingerprint of leda-x86"
ssh-keyscan -p 2222 -H leda-x86.leda-network >> ~/.ssh/known_hosts 2> /dev/null
echo "- Adding SSH fingerprint of leda-arm64"
ssh-keyscan -p 2222 -H leda-arm64.leda-network >> ~/.ssh/known_hosts 2> /dev/null
echo ""
echo " From here, you can continue to log in to one of the guests:"
echo "  ssh leda-x86"
echo "  ssh leda-arm64"
echo ""
echo " Or monitor MQTT messages:"
echo "  mosquitto_sub -h leda-mqtt-broker.leda-network -t '#' -v"
echo ""

bash