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

echo "Executing Eclipse Leda tests..."

TESTSUITE=$1

if [ "${TESTSUITE}" == "--help" ]; then
    echo "Please specifiy test suite (.robot file) as first command line argument"
    echo "Use --mergeall to merge all"
    exit 0
fi

if [ "${TESTSUITE}" == "--mergeall" ]; then
    ALL_REPORTS=$(find robot-output -wholename "robot-output/*/output.xml" -printf "%p ")
    echo "Merging output reports: ${ALL_REPORTS}"
    rebot \
        --name "Leda" \
        --xunit robot-output/leda-tests-xunit.xml \
        --report robot-output/report.html \
        --log robot-output/log.html \
        --output robot-output/output.xml \
        ${ALL_REPORTS}
    exit 0
fi

if [ -z ${TESTSUITE} ]; then
    echo "ERROR: Please provide name of .robot file to execute"
    echo "Available test suites:"
    find -name "*.robot"
    exit 1
fi

echo "- Test Suite: ${TESTSUITE}"
echo "- Robot Framework version: $(robot --version)"

mkdir -p ~/.ssh/
echo "- SSH Hosts Configuration in ~/.ssh/config"
echo "- Adding SSH fingerprint of leda-x86"
ssh-keyscan -p 2222 -H leda-x86.leda-bridge >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -p 2222 -H leda-x86.leda-network >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -p 2222 -H 192.168.8.4 >> ~/.ssh/known_hosts 2> /dev/null
echo "- Adding SSH fingerprint of leda-arm64"
ssh-keyscan -p 2222 -H leda-arm64.leda-bridge >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -p 2222 -H leda-arm64.leda-network >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -p 2222 -H 192.168.8.5 >> ~/.ssh/known_hosts 2> /dev/null

RECORD_LOGS_FOR_SERVICE_UNITS=(
    "containerd"
    "dbus"
    "container-management"
    "kanto-auto-deployer"
    "rauc"
    "rauc-mark-good"
)

echo "- Starting MQTT listener for X86-64"
mkdir -p robot-output/${TESTSUITE}/x86/
MQTT_DEBUG_LOG="robot-output/${TESTSUITE}/x86/mqtt-debug.log"
mosquitto_sub -t '#' -p 1883 -h leda-x86.leda-network -v -d > ${MQTT_DEBUG_LOG} 2>&1 &
MQTT_LISTENER_PID=$!

echo "- Executing QEMU X86-64 tests"
robot \
    --name ${TESTSUITE}_X86 \
    --variablefile vars-x86.yaml \
    --metadata Leda-Target:X86-64 \
    --settag x86 \
    --loglevel INFO \
    --debugfile leda-tests-debug.log \
    --xunit leda-tests-xunit.xml \
    --outputdir robot-output/${TESTSUITE}/x86 \
    ${TESTSUITE}

echo "- Stopping MQTT listener for X86-64 on PID ${MQTT_LISTENER_PID}"
kill ${MQTT_LISTENER_PID}

for i in "${RECORD_LOGS_FOR_SERVICE_UNITS[@]}"
do
   echo "- Collecting logs of service $i"
   ssh -p 2222 root@leda-x86.leda-network journalctl --unit=$i > robot-output/${TESTSUITE}/x86/log.$i.txt
done

#ssh -p 2222 root@leda-x86.leda-network journalctl --help
#ssh -p 2222 root@leda-x86.leda-network journalctl --system --all --no-pager --output=short-monotonic
#ssh -p 2222 root@leda-x86.leda-network journalctl --boot --all --no-pager --output=short-monotonic
#ssh -p 2222 root@leda-x86.leda-network journalctl --dmesg --all --no-pager --output=short-monotonic

echo "- Starting MQTT listener for ARM64"
mkdir -p robot-output/${TESTSUITE}/arm64/
MQTT_DEBUG_LOG="robot-output/${TESTSUITE}/arm64/mqtt-debug.log"
mosquitto_sub -t '#' -p 1883 -h leda-arm64.leda-network -v -d > ${MQTT_DEBUG_LOG} 2>&1 &
MQTT_LISTENER_PID=$!

echo "- Executing QEMU ARM-64 tests"
robot \
    --name ${TESTSUITE}_ARM64 \
    --variablefile vars-arm64.yaml \
    --metadata Leda-Target:ARM-64 \
    --settag arm64 \
    --loglevel INFO \
    --debugfile leda-tests-debug.log \
    --xunit leda-tests-xunit.xml \
    --outputdir robot-output/${TESTSUITE}/arm64 \
    ${TESTSUITE}

echo "- Stopping MQTT listener for ARM64 on PID ${MQTT_LISTENER_PID}"
kill ${MQTT_LISTENER_PID}

for i in "${RECORD_LOGS_FOR_SERVICE_UNITS[@]}"
do
   echo "- Collecting logs of service $i"
   ssh -p 2222 root@leda-arm64.leda-network journalctl --unit=$i > robot-output/${TESTSUITE}/arm64/log.$i.txt
done
