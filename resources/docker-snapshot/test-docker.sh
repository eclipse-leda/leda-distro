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

echo "Eclipse Leda - Robot-based Smoke Tests"
echo "Start with --help to get see options."

CMD=$1

if [ "${CMD}" == "--help" ]; then
    echo "Usage:"
    echo "    $0 <command | test suite filename>"
    echo ""
    echo "Purpose: Executes smoke tests (system and integration tests) in a Dockerized environment."
    echo "Requires to be run in Leda docker-compose setup."
    echo ""
    echo "Commands:"
    echo "    --help                   this help text"
    echo "    <test suite filename>    the filename of a .robot test (without the path)"
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
TESTSUITES=$(find ${SEARCHPATH} -name "*.robot" -printf "%f\n" | sort -n)
if [ ! -z ${CMD} ]; then
    TESTSUITES=$(find ${SEARCHPATH} -name "${CMD}" -printf "%f\n")
fi
while IFS= read -r TESTSUITE; do
    echo "Verifying test suite ${TESTSUITE}"
    ROBOTFILE="${SEARCHPATH}/${TESTSUITE}"
    if [ ! -f "${ROBOTFILE}" ]; then
        echo "ERROR: Robot file ${CMD} not found in path ${SEARCHPATH}"
        echo "Available robot files:"
        find ${SEARCHPATH} -name "*.robot" -printf "%f\n" | sort -n
        exit 2
    fi
done <<< "${TESTSUITES}"

echo "Rebuilding tests container"
docker compose --profile tests build leda-tests

echo "Creating report folder"
mkdir -m 777 -p leda-tests-reports

trap ctrl_c INT

function generateMergedReports() {
    echo "Merging all test suites reports into a single aggregated report..."
    docker compose --profile tests run --no-TTY --interactive=false --no-deps --rm leda-tests --mergeall
}

function shutdownContainers() {
    echo "Stopping containers and removing volumes..."
    docker compose down
    docker compose stop devshell leda-x86 leda-arm64 leda-tests
    docker compose rm --stop --force --volumes leda-x86 leda-arm64
    docker volume rm --force leda-x86 leda-arm64
}

function ctrl_c() {
        echo "************************************************"
        echo "*** Trapped CTRL-C, gracefully shutting down ***"
        echo "*** Please wait                              ***"
        echo "************************************************"
        shutdownContainers
        generateMergedReports
        exit 10
}

echo "Executing test suites..."
while IFS= read -r TESTSUITE; do
    echo "- Found test suite ${TESTSUITE}"
done <<< "${TESTSUITES}"

while IFS= read -r TESTSUITE; do
    echo "Preparing test suite ${TESTSUITE}"
    echo "- Stopping containers"
    docker compose stop leda-x86 leda-arm64
    echo "- Removing containers"
    docker compose rm --stop --force --volumes leda-x86 leda-arm64
    echo "- Removing volumes"
    docker volume rm --force leda-x86 leda-arm64
    echo "- Starting up docker compose services to become healthy"
    docker compose up --detach --wait
    echo "- Executing test suite ${TESTSUITE}"
    docker compose --profile tests run --name leda-tests --no-TTY --interactive=false --rm leda-tests ${TESTSUITE}
done <<< "${TESTSUITES}"

shutdownContainers
generateMergedReports

exit 0
