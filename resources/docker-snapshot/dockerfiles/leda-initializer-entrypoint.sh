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
    echo "Preparing ${TARGET_HOSTNAME} ..."
    echo "- Adding SSH Host Key"
    ssh-keyscan -p 2222 -H ${TARGET_HOSTNAME} >> ~/.ssh/known_hosts 2> /dev/null
    echo "- Waiting for container management to become active (running)"
    ssh -p 2222 root@${TARGET_HOSTNAME} systemctl is-active --wait container-management
    echo "- Sending MQTT to simulate cloud connection"
    mosquitto_pub -h ${TARGET_HOSTNAME} -t "edge/thing/response" -f simulate-cloud-connection.json
    sleep 1
    echo "- Sending MQTT to enable container metrics"
    mosquitto_pub -h ${TARGET_HOSTNAME} -t "command//dummy-namespace:dummy-gateway:dummy-device-id:edge:containers/req/3fdc463c-293c-4f39-ab19-24aef7944550/request" -f enable-container-metrics.json
    echo "- Finished"
}

function verifyTarget() {
    local TARGET_HOSTNAME=$1
    echo "Verifying ${TARGET_HOSTNAME} ..."
    #TOPIC="e/<tenantId>/<gatewayId>:<deviceId>:edge:containers"
    EXPECTED_TOPIC="e/dummy-tenant-id/dummy-namespace:dummy-gateway:dummy-device-id:edge:containers"
    # Wait for first fresh (not retained) message on the topic for maximum 10 seconds
    mosquitto_sub -h ${TARGET_HOSTNAME} -t "${EXPECTED_TOPIC}" -W 10 -C 1 -R -v
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

prepareTarget leda-x86.leda-network
prepareTarget leda-arm64.leda-network

verifyTarget leda-x86.leda-network
verifyTarget leda-arm64.leda-network

echo "Preparation done."

exit 0