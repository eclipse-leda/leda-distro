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
ALIEN_OUTPUT="${WORKSPACE}/build/tmp/deploy/aliensrc"
PROJECT_NAME="leda"
RELEASE_TAG="${GIT_TAG}"

export PYTHONPATH=${WORKSPACE}/poky/bitbake/lib:${WORKSPACE}/poky/meta/lib

echo "Project name       : ${PROJECT_NAME}"
echo "Release tag        : ${RELEASE_TAG}"
echo "Workspace directory: ${WORKSPACE}"
echo "Build directory    : ${BUILD_DIR}"
echo "Output directory   : ${OUTPUT_DIR}"
echo "AliensRC directory : ${ALIEN_OUTPUT}"

mkdir -p ${OUTPUT_DIR}
mkdir -p ${ALIEN_OUTPUT}

# usage: tinfoilhat [-h] OUTPUT_DIR PROJECT_NAME RELEASE_TAG [BUILD_DIR [BUILD_DIR ...]]
time tinfoilhat ${OUTPUT_DIR} ${PROJECT_NAME} ${RELEASE_TAG} ${BUILD_DIR}

# usage: aliensrc_creator [-h] [--tmpdir TMPDIR] [--skip-existing] OUTPUT_DIR [TINFOILHAT_DIR [TINFOILHAT_DIR ...]]
time aliensrc_creator ${ALIEN_OUTPUT} ${OUTPUT_DIR}

echo "Project name       : ${PROJECT_NAME}"
echo "Release tag        : ${RELEASE_TAG}"
echo "Workspace directory: ${WORKSPACE}"
echo "Build directory    : ${BUILD_DIR}"
echo "Output directory   : $(du -s -h ${OUTPUT_DIR})"
echo "AliensRC directory : $(du -s -h ${ALIEN_OUTPUT})"

echo ""
echo "Done!"