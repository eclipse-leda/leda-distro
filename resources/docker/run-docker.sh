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

# Run the system
if ! docker compose up --no-recreate --remove-orphans --detach
then
    echo "Error starting containers, aborting."
    echo "If you were not authenticated, try: docker login ghcr.io --username <github-username>"
    exit 1
fi 

