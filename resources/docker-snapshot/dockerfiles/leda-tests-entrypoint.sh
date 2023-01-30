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

echo "- Current working directory: $(pwd)"
echo "- Robot Framework version: $(robot --version)"

robot \
    --variablefile leda-tests-variables.yaml \
    --loglevel ERROR \
    --debugfile leda-tests-debug.log \
    --xunit leda-tests-xunit.xml \
    --outputdir robot-output \
    *.robot

# cat output.xml
# cat debug.log
