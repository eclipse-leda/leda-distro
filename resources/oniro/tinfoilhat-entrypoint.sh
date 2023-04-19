#!/bin/bash

export PYTHONPATH=/workspace/poky/bitbake/lib:/workspace/poky/meta/lib

# usage: tinfoilhat [-h] OUTPUT_DIR PROJECT_NAME RELEASE_TAG [BUILD_DIR [BUILD_DIR ...]]
OUTPUT_DIR="output"
PROJECT_NAME="leda"
RELEASE_TAG="v0.0.0"
BUILD_DIR="/workspace/build"
tinfoilhat ${OUTPUT_DIR} ${PROJECT_NAME} ${RELEASE_TAG} ${BUILD_DIR}
