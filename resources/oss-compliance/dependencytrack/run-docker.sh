#!/bin/bash

docker build --tag leda/sbomconverter -f Dockerfile.sbomconverter .
mkdir output
docker run --rm --volume "$(pwd)/../../../build:/build" --volume "$(pwd)/output:/output" leda/sbomconverter
