#!/bin/bash
#
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

# Build the container with the latest Eclipse Leda runtime archive from github.com
docker build \
    --tag leda-runner-tests \
    --file Dockerfile.runner-tests \
    --secret id=githubtoken,env=GITHUB_TOKEN \
    --build-arg GITHUB_REPOSITORY=${GITHUB_REPOSITORY} \
    ..

# Define our test case execution function
function runTest() {
    local TEST="$1"
    local TESTCMD="$2"
    local EXPECT="$3"
    ACTUAL=$($TESTCMD)
    if echo "$ACTUAL" | grep -q "${EXPECT}"; then
        echo "Test success: ${TEST}"
    else
        echo "FATAL: Test FAILED: ${TEST}"
        echo "    Command: ${TESTCMD}"
        echo "    Expected output: ${EXPECT}"
        echo "    Actual output:"
        echo $ACTUAL
    fi
}

# Run each test case
runTest "Unprivileged user, Unprivileged container" \
    "docker run -it --rm leda-runner-tests" \
    "falling back to unprivileged mode"

runTest "Unprivileged user, privileged container" \
    "docker run -it --rm --privileged leda-runner-tests" \
    "falling back to unprivileged mode"

runTest "Unprivileged user, privileged container, host networking" \
    "docker run -it --rm --privileged --network=host leda-runner-tests" \
    "falling back to unprivileged mode"

runTest "Root user, unprivileged container" \
    "docker run -it --rm --user root leda-runner-tests" \
    "falling back to unprivileged mode"

runTest "Root user, privileged container, host networking" \
    "docker run -it --rm --privileged --network=host --user root leda-runner-tests" \
    "using privileged mode"

runTest "Root user, privileged container" \
    "docker run -it --rm --privileged --user root leda-runner-tests" \
    "using privileged mode"

#
# Use the following commands to manually run the tests cases:
#   docker run -it --rm leda-runner-tests
#   docker run -it --rm --privileged leda-runner-tests
#   docker run -it --rm --privileged --network=host leda-runner-tests
#   docker run -it --rm --privileged --network=host --user root leda-runner-tests
#   docker run -it --rm --network=host --user root leda-runner-tests
#   docker run -it --rm --user root leda-runner-tests
#   docker run -it --rm --privileged --sysctl net.ipv4.ip_forward=1 leda-runner-tests
#   docker run -it --rm --privileged --sysctl net.ipv4.ip_forward=1 --user root leda-runner-tests
#
# To inspect the container, open a new shell inside of the container without executing run-leda.sh entrypoint script:
#   docker run --entrypoint /bin/bash --tty -i leda-runner-tests
#   docker run --privileged --network=host --user root --entrypoint /bin/bash --tty -i leda-runner-tests
#
