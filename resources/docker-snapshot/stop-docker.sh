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

# Shut down all services
echo "Shutting down all services..."
docker compose --profile tests --profile tools --profile metrics --profile disabled down

# Kill any other containers currently still running
echo "Killing remaining containers..."
docker compose --profile tools --profile tests --profile metrics --profile disabled kill
echo ""

# Remove all exited containers
echo "Removing all containers and anonymous volumes..."
docker compose --profile tools --profile tests --profile metrics --profile disabled rm --force --stop --volumes
echo ""


