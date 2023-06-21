#!/bin/bash

find /workspaces/leda-distro-fork/resources/oss-compliance/aliens4friends/aliens4friends-pool/userland -type l -name "*.final.spdx" | parallel ./a4f-to-cyclonedx.sh {}

# docker run -it --rm cyclonedx/cyclonedx-cli merge --help

#        --hierarchical \
docker run \
        --volume "$(pwd)/output/:/output" \
        --rm \
        cyclonedx/cyclonedx-cli \
        merge \
        --group eclipse-leda \
        --name "Eclipse Leda" \
        --version "0.1.0" \
        --input-format json \
        --output-format json \
        --input-files $(find output -name "*.cyclonedx.json" -printf '/output/%f ') \
        --output-file "/output/merged.cyclonedx.json"

