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
FINISHED_TESTSUITES=()

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

function showSummary() {
    for FINISHED_TESTSUITE in "${FINISHED_TESTSUITES[@]}"
    do
        echo "- Finished test suite: ${FINISHED_TESTSUITE}"
    done
}

function generateMergedReports() {
    echo "Merging all test suites reports into a single aggregated report..."
    docker compose --profile tests run --no-TTY --interactive=false --no-deps --rm leda-tests --mergeall
}

function shutdownContainers() {
    echo "Shutting down containers and removing volumes..."
    echo "- Explicitly stopping devshell, leda-tests and leda containers"
    docker compose --profile tests stop devshell leda-x86 leda-arm64 leda-tests
    echo "- Killing potentially running left-over containers"
    docker compose --profile tools --profile tests --profile metrics --profile disabled kill
    echo ""
    echo "- Removing containers leda-x86 and leda-arm64"
    docker compose --profile tests rm --stop --force --volumes leda-x86 leda-arm64
    echo "- Removing volumes leda-x86 and leda-arm64"
    docker volume rm --force leda-x86 leda-arm64
}

function generalShutdownTasks() {
        shutdownContainers
        generateMergedReports
        showSummary
}

function ctrl_c() {
        echo "************************************************"
        echo "*** Trapped CTRL-C, gracefully shutting down ***"
        echo "*** Please wait                              ***"
        echo "************************************************"
        generalShutdownTasks
        exit 10
}

echo "Executing test suites..."
while IFS= read -r TESTSUITE; do
    echo "- Found test suite ${TESTSUITE}"
done <<< "${TESTSUITES}"

while IFS= read -r TESTSUITE; do
    echo "${TESTSUITE}: Preparing test suite (cleanup)"
    echo "${TESTSUITE}: - Stopping containers leda-x86 and leda-arm64"
    docker compose stop leda-x86 leda-arm64
    echo "${TESTSUITE}: - Removing container leda-tests"
    docker rm --force leda-tests > /dev/null 2>&1
    echo "${TESTSUITE}: - Removing containers leda-x86 and leda-arm64"
    docker compose rm --stop --force --volumes leda-x86 leda-arm64
    echo "${TESTSUITE}: - Removing volumes leda-x86 and leda-arm64"
    docker volume rm --force leda-x86 leda-arm64
    echo "${TESTSUITE}: Executing test suite"
    echo "${TESTSUITE}: - Starting up docker compose services (minimal) to become healthy"
    docker compose up --detach --wait
    echo "${TESTSUITE}: - Starting new test suite container"
    docker compose --profile tests run --detach --name leda-tests --no-TTY --interactive=false --rm leda-tests ${TESTSUITE}
    echo "${TESTSUITE}: - Waiting for tests to finish"
    docker logs -f leda-tests &
    docker wait leda-tests
    FINISHED_TESTSUITES+=("${TESTSUITE}")
done <<< "${TESTSUITES}"

generalShutdownTasks

exit 0
