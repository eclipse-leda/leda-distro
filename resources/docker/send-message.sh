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

if [ $# -eq 0 ]
then
    echo "Eclipse Leda - C2D Message Helper"
    echo ""
    echo "Usage: $0 <Azure-IoT-Hub-Name>"
    echo ""
    echo "Arguments:"
    echo "  <Azure-IoT-Hub-Name> - Name of the Azure IoT Hub (without *.azure-devices.net)"
    echo ""
    exit 1
fi

if ! command -v az &> /dev/null
then
    echo "Azure CLI (az) could not be found, please install. See https://learn.microsoft.com/en-us/cli/azure/install-azure-cli for instructions"
    exit
fi

DEVICE_OWNER=$GITHUB_USER

function sendMessage() {
  local DEVICE_ID="$1"
  local FILENAME="$2"
  CORRELATION_ID=$(cat /proc/sys/kernel/random/uuid)

  echo "Sending Self Update Message to device ${DEVICE_ID}"
  echo "via IoT Hub: ${IOT_HUB}"
  echo "using Correlation ID: ${CORRELATION_ID}"

  DESIRED_STATE=$(jq --raw-input --slurp <<EOF
  apiVersion: "sdv.eclipse.org/v1"
  kind: SelfUpdateBundle
  metadata:
    name: self-update-bundle-example
  spec:
    bundleName: swdv-arm64-build42
    bundleVersion: v1beta3
    bundleDownloadUrl: http://leda-bundle-server/${FILENAME}
    bundleTarget: base
EOF
  )


  MSG_DATA_1=$(cat <<EOF
  {
      "appId": "mc-ota-update",
      "cmdName": "desiredstate.update",
      "cId": "${CORRELATION_ID}",
      "eVer": "2.0",
      "pVer": "1.0",
      "p": ${DESIRED_STATE}
  }
EOF
  )

  echo "Sending message to ${DEVICE_ID}..."
  az iot device c2d-message send -n ${IOT_HUB} -d ${DEVICE_ID} --content-type "application/json" --data "${MSG_DATA_1}"

}

sendMessage "leda-docker-${DEVICE_OWNER}-x86" "sdv-rauc-bundle-qemux86-64.raucb"
sendMessage "leda-docker-${DEVICE_OWNER}-arm64" "sdv-rauc-bundle-qemuarm64.raucb"
