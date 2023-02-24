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

mkdir -p ~/.ssh/

function prepareTarget() {
    local TARGET_HOSTNAME=$1
    local DEVICE_ID=$2
    echo "Preparing ${TARGET_HOSTNAME} ..."
    echo "- Adding SSH Host Key"
    ssh-keyscan -p 2222 -H ${TARGET_HOSTNAME} >> ~/.ssh/known_hosts 2> /dev/null
    echo "- Waiting for container management to become active (running)"
    ssh -p 2222 root@${TARGET_HOSTNAME} systemctl is-active --wait container-management
    echo "- Sending MQTT to simulate cloud connection"
    sleep 5
    cat simulate-cloud-connection.json | sed "s/dummy-device-id/${DEVICE_ID}/" | mosquitto_pub -h ${TARGET_HOSTNAME} -t "edge/thing/response" -s
    sleep 1
    echo "- Sending MQTT to enable container metrics"
    cat enable-container-metrics.json | sed "s/dummy-device-id/${DEVICE_ID}/" | mosquitto_pub -h ${TARGET_HOSTNAME} -t "command//dummy-namespace:dummy-gateway:${DEVICE_ID}:edge:containers/req/3fdc463c-293c-4f39-ab19-24aef7944550/request" -s
    echo "- Finished"
}

function verifyTarget() {
    local TARGET_HOSTNAME=$1
    local DEVICE_ID=$2
    echo "Verifying ${TARGET_HOSTNAME} ..."
    #TOPIC="e/<tenantId>/<gatewayId>:<deviceId>:edge:containers"
    EXPECTED_TOPIC="e/dummy-tenant-id/dummy-namespace:dummy-gateway:${DEVICE_ID}:edge:containers"
    # Wait for first fresh (not retained) message on the topic for maximum 10 seconds
    mosquitto_sub -h ${TARGET_HOSTNAME} -t "${EXPECTED_TOPIC}" -W 20 -C 1 -R -v
    RC=$?
    echo "- Return code: ${RC}"
    if [ $RC = 0 ]; then
        echo "- Success"
    elif [ $RC = 27 ]; then
        echo "- Error: Timeout waiting for first container metrics response"
        # Fail fast
        exit 1
    fi
}

prepareTarget leda-x86.leda-network leda-x86
prepareTarget leda-arm64.leda-network leda-arm64

verifyTarget leda-x86.leda-network leda-x86
verifyTarget leda-arm64.leda-network leda-arm64

echo "Preparation done."

exit 0