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

export LEDA_VERSION_TAG="latest"
docker compose build 
docker compose push

export LEDA_VERSION_TAG=$(git describe --tags)
docker compose build 
docker compose push 
