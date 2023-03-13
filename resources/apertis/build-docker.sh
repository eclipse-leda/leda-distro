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
# Build and Run the Leda SDV Core components stack on Apertis IoT (QEMU X86)
#
#set -e

if ! command -v docker &> /dev/null
then
    echo "Error: Docker could not be found, please install Docker."
    exit 1
fi

# Set the build context to "../.." to allow to access the Yocto build workspace
# for copying the ovmf.qcow2 file
docker build --tag ghcr.io/eclipse-leda/leda-distro/leda-apertis-x86 --file Dockerfile.apertis ../..
