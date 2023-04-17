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
# Build and Run Leda on X86 and ARM64 in Docker Containers
#
#set -e

if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, please install Docker."
    exit
fi

docker rm --force leda-apertis-x86
docker run --name leda-apertis-x86 --tty --interactive ghcr.io/eclipse-leda/leda-distro/leda-apertis-x86

# docker run --tty --interactive --entrypoint /bin/bash leda-apertis-x86
# docker exec --tty --interactive leda-apertis-x86 /bin/bash
# docker push ghcr.io/eclipse-leda/leda-distro/leda-apertis-x86