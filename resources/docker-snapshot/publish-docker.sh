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

if [ -z "${GITHUB_TOKEN}" ]; then
    echo "Error: No GITHUB_TOKEN environment variable. Required for pushing to container registry"
    exit 2
fi

echo "${GITHUB_TOKEN}" | docker login --username "github" --password-stdin ghcr.io

# Manually testing:
# docker build --tag "ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest" --file dockerfiles/Dockerfile.leda-quickstart-x86 ../..
# docker run -it --privileged --device=/dev/kvm:/dev/kvm --device=/dev/net/tun:/dev/net/tun ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest
# docker push ghcr.io/eclipse-leda/leda-distro/leda-quickstart-x86:latest

export LEDA_VERSION_TAG="latest"
docker compose --profile tools --profile disabled --profile tests --profile metrics build 
docker compose --profile tools --profile disabled --profile tests --profile metrics push

export LEDA_VERSION_TAG=$(git describe --tags)
docker compose --profile tools --profile disabled --profile tests --profile metrics build 
docker compose --profile tools --profile disabled --profile tests --profile metrics push 
