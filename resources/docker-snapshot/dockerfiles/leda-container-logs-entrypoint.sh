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

function prepareLogs() {
    local TARGET=$1
    ssh-keyscan -p 2222 -H ${TARGET} >> ~/.ssh/known_hosts 2> /dev/null
    ssh -p 2222 root@${TARGET} mkdir -p /data/var/opentelemetry
    scp -P 2222 ./config.yaml root@${TARGET}:/data/var/opentelemetry
    scp -P 2222 ./otel-collector.json root@${TARGET}:/data/var/containers/manifests_dev
    ssh -p 2222 root@${TARGET} kanto-cm stop --force --name otelcollector
    ssh -p 2222 root@${TARGET} kanto-cm remove --force --name otelcollector
    ssh -p 2222 root@${TARGET} kanto-auto-deployer /data/var/containers/manifests_dev
}

prepareLogs "leda-x86.leda-network"
prepareLogs "leda-arm64.leda-network"

exit 0