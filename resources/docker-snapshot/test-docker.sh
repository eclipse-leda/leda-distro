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

CMD=$1

if [ "${CMD}" == "--help" ]; then
    echo "$0 <command | test suite filename>"
    echo ""
    echo "Commands:"
    echo " --help: this help text"
    echo " test suite filename: the filename of a .robot test (without the path)"
    echo ""
    echo " Note: Without any arguments, will execute all test suites found in dockerfiles/leda-tests/*.robot"
    exit 0
fi

if ! command -v docker &> /dev/null
then
    echo "Docker could not be found, please install Docker."
    exit 1
fi

SEARCHPATH="dockerfiles/leda-tests"
TESTSUITES=$(find ${SEARCHPATH} -name "*.robot" -printf "%f\n")
if [ ! -z ${CMD} ]; then
    TESTSUITES=$(find ${SEARCHPATH} -name "${CMD}" -printf "%f\n")
fi
while IFS= read -r TESTSUITE; do
    echo "Verifying test suite ${TESTSUITE}"
    ROBOTFILE="${SEARCHPATH}/${TESTSUITE}"
    if [ ! -f "${ROBOTFILE}" ]; then
        echo "ERROR: Robot file ${CMD} not found in path ${SEARCHPATH}"
        echo "Available robot files:"
        find ${SEARCHPATH} -name "*.robot" -printf "%f\n"
        exit 2
    fi
done <<< "${TESTSUITES}"

echo "Rebuilding tests container"
docker compose --profile tests build leda-tests

echo "Creating report folder"
mkdir -m 777 -p leda-tests-reports

echo "Executing test suites..."
while IFS= read -r TESTSUITE; do
    echo "Executing test suite ${TESTSUITE}"
    echo "- Cleaning existing volumes of leda-x86 and leda-arm64"
    docker compose rm --volumes --force --stop leda-x86 leda-arm64
    echo "- Executing test cases (waiting for containers to become healthy)"
    docker compose --profile tests run --no-TTY --rm leda-tests ${TESTSUITE}
done <<< "${TESTSUITES}"

echo "Stopping containers..."
docker compose rm --volumes --force --stop leda-x86 leda-arm64

echo "Merging all test suites reports into a single aggregated report..."
docker compose --profile tests run --no-deps --rm leda-tests --mergeall
