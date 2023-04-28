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

WORKSPACE="${1}"
GIT_TAG="${2}"

BUILD_DIR="${WORKSPACE}/build"
OUTPUT_DIR="${WORKSPACE}/build/tmp/deploy/tinfoilhat"
PROJECT_NAME="leda"
RELEASE_TAG="${GIT_TAG}"

export PYTHONPATH=${WORKSPACE}/poky/bitbake/lib:${WORKSPACE}/poky/meta/lib

echo "Project name       : ${PROJECT_NAME}"
echo "Release tag        : ${RELEASE_TAG}"
echo "Workspace directory: ${WORKSPACE}"
echo "Build directory    : ${BUILD_DIR}"
echo "Output directory   : ${OUTPUT_DIR}"

# usage: tinfoilhat [-h] OUTPUT_DIR PROJECT_NAME RELEASE_TAG [BUILD_DIR [BUILD_DIR ...]]
time tinfoilhat ${OUTPUT_DIR} ${PROJECT_NAME} ${RELEASE_TAG} ${BUILD_DIR}
