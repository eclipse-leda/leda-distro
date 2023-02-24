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
    echo "Error: Docker could not be found, please install Docker."
    exit 1
fi

if [ ! -d ../../build/tmp/deploy/images/qemux86-64 ];
then
    echo "Error: build/tmp/deploy/images/qemux86-64 is missing. Did you run the full build?"
    exit 2
fi

if [ ! -d ../../build/tmp/deploy/images/qemuarm64 ];
then
    echo "Error: build/tmp/deploy/images/qemuarm64 is missing. Did you run the full build?"
    exit 2
fi

docker compose --profile tools --profile disabled --profile tests --profile metrics build 
