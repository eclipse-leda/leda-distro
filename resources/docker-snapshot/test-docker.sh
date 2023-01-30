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
# Run test cases against the docker containers
#
#set -e

if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, please install Docker."
    exit
fi

docker compose --profile tests build leda-tests
docker compose --profile tests run --rm leda-tests
