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

function buildAndRun() {
    BASE_IMAGE=$1
    echo "Building for ${BASE_IMAGE}"
    CONTAINER_IMAGE_HASH=$(docker build --build-arg BASE_IMAGE=${BASE_IMAGE} -q -f Dockerfile.debian .) || exit 1
    echo "Performing test run on ${BASE_IMAGE}"
    docker run --rm -it ${CONTAINER_IMAGE_HASH}
    RC=$?
    if [ $RC -eq 0 ]; then
        echo "Success on ${BASE_IMAGE}"
    else 
        echo "Failed on ${BASE_IMAGE}"
        exit 1
    fi
}

buildAndRun "debian:bookworm"

exit 0

buildAndRun "debian:bullseye"
buildAndRun "debian:buster"

buildAndRun "ubuntu:lunar"
buildAndRun "ubuntu:kinetic"
buildAndRun "ubuntu:jammy"
buildAndRun "ubuntu:focal"

buildAndRun "archlinux"
buildAndRun "amazonlinux"
buildAndRun "photon"
buildAndRun "rockylinux"
