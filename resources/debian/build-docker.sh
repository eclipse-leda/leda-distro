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

function buildImage() {
    IMAGE="$1"
    echo "Building ${IMAGE}"
    docker build --quiet --tag ghcr.io/eclipse-leda/leda-distro/leda-test-${IMAGE} --file Dockerfile.${IMAGE} dockerfiles/    
}

buildImage debian10
buildImage debian11
buildImage debian12
buildImage ubuntu18
buildImage ubuntu20
buildImage ubuntu22
buildImage ubuntu23
