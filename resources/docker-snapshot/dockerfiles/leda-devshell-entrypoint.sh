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
ARG=$1

echo "Welcome to Eclipse Leda Docker DevShell"
echo "Argument: ${ARG}"
echo ""
echo -n "Initializing environment..."
mkdir -p ~/.ssh/
echo -n "SSH for leda-x86..."
ssh-keyscan -t ecdsa -p 2222 -H leda-x86.leda-network >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -t ecdsa -p 2222 -H 192.168.8.4 >> ~/.ssh/known_hosts 2> /dev/null
echo -n "SSH for leda-arm64..."
ssh-keyscan -t ecdsa -p 2222 -H leda-arm64.leda-network >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -t ecdsa -p 2222 -H 192.168.8.5 >> ~/.ssh/known_hosts 2> /dev/null
echo ""

if [ "$ARG" == "help" ]; then
    echo "Usage: ./devshell-docker.sh [<command>]"
    echo ""
    echo "Commands:"
    echo "  help        - This help"
    echo "  shell       - Open a shell (default)"
    echo "  mqtt        - Subscribe and dump all MQTT topics"
    echo "  leda-x86    - Login to Leda-X86 instance"
    echo "  leda-arm64  - Login to Leda-ARM64 instance"
    echo ""
elif [ "$ARG" == "shell" ]; then
    echo ""
    echo " From here, you can continue to log in to one of the guests:"
    echo "  ssh leda-x86"
    echo "  ssh leda-arm64"
    echo ""
    echo " Or monitor MQTT messages:"
    echo "  mosquitto_sub -h leda-mqtt-broker.leda-network -t '#' -v"
    echo ""
    bash
elif [ "$ARG" == "leda-x86" ]; then
    ssh leda-x86
elif [ "$ARG" == "leda-arm64" ]; then
    ssh leda-arm64
elif [ "$ARG" == "mqtt" ]; then
    mosquitto_sub -h leda-mqtt-broker.leda-network -t '#' | jq -c
fi

exit 0