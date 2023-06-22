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

# Fail early
set -e

function testImage() {
    IMAGE="$1"
    if docker run --rm --privileged --cap-add=SYS_ADMIN ghcr.io/eclipse-leda/leda-distro/leda-test-${IMAGE} ; then
        echo "Succeeded: $IMAGE"
    else
        echo "Failed: $IMAGE"
    fi
}

testImage "debian10"
testImage "debian11"
testImage "debian12"
testImage "ubuntu18"
testImage "ubuntu20"
testImage "ubuntu22"
testImage "ubuntu23"