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

echo "Executing Eclipse Leda tests..."
echo "- Robot Framework version: $(robot --version)"

mkdir -p ~/.ssh/
echo "- SSH Hosts Configuration in ~/.ssh/config"
echo "- Adding SSH fingerprint of leda-x86"
ssh-keyscan -p 2222 -H leda-x86.leda-network >> ~/.ssh/known_hosts 2> /dev/null
echo "- Adding SSH fingerprint of leda-arm64"
ssh-keyscan -p 2222 -H leda-arm64.leda-network >> ~/.ssh/known_hosts 2> /dev/null

echo "- Executing QEMU X86-64"

robot \
    --name "Leda x86-64 Tests" \
    --variablefile vars-x86.yaml \
    --loglevel INFO \
    --debugfile leda-tests-debug.log \
    --xunit leda-tests-xunit.xml \
    --outputdir robot-output/x86 \
    *.robot

echo "- Executing QEMU ARM-64"

robot \
    --name "Leda ARM-64 Tests" \
    --variablefile vars-arm64.yaml \
    --loglevel INFO \
    --debugfile leda-tests-debug.log \
    --xunit leda-tests-xunit.xml \
    --outputdir robot-output/arm64 \
    *.robot

echo "- Merging output reports"
rebot --output robot-output/output.xml robot-output/x86/output.xml robot-output/arm64/output.xml 