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
# Build and Run Leda on X86 and ARM64 in Docker Containers
#
#set -e

if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, please install Docker."
    exit
fi

# Docker setup may be as follows:
# sudo ip link add dev vcan0 type vcan
# sudo ip link add dev vcan1 type vcan
# sudo ip link set up vcan0
# sudo ip link set up vcan1
# echo "Installing Docker Network Plugin for VXCAN to support CAN-Bus networks"
# if ! docker plugin install --grant-all-permissions wsovalle/vxcan
# then
#     echo "Error installing Docker Network Plugin for VXCAN (CAN-Bus)"
#     echo "Continuing..."
# else
# fi

if ! docker compose up --no-recreate --remove-orphans --detach
then
    echo "Error starting containers, aborting."
    exit 1
fi 

echo "Eclipse Leda Docker setup started."
echo "You can now:"
echo "- Log in to the devshell:         docker compose run devshell"
echo "- or check status of containers:  docker compose ps"
echo "- or send a message:              ./send-message.sh"
echo "- or watch MQTT:                  mosquitto_sub -h localhost -p 1883 -t '#' -v"
echo "- or stop the containers:         ./stop-docker.sh"
echo "- access Grafana:                 http://127.0.0.1:8300/  (Login: admin/admin)"
echo "- access Prometheus:              http://127.0.0.1:9090"
