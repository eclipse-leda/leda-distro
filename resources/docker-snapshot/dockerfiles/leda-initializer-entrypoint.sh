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

mkdir -p ~/.ssh/
ssh-keyscan -p 2222 -H leda-x86 >> ~/.ssh/known_hosts 2> /dev/null
ssh-keyscan -p 2222 -H leda-arm64 >> ~/.ssh/known_hosts 2> /dev/null

# Perform things here

exit 0