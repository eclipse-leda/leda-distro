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

git clone https://github.com/openembedded/bitbake
pushd bitbake
docker build --tag "leda-bitbake-hashserv:latest" -f ./contrib/hashserv/Dockerfile .
docker run --detach --rm --publish 1234:1234 --name bb-hashserv leda-bitbake-hashserv:latest -b :1234
