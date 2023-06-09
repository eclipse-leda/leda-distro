#!/bin/bash

# docker run --rm cyclonedx/cyclonedx-cli convert --input-format spdx --output-format json --input-file $1 --output-file $2

# docker run -it --rm cyclonedx/cyclonedx-cli --help
# docker run -it --rm cyclonedx/cyclonedx-cli merge --help
# cat /workspaces/leda-distro-fork/resources/oss-compliance/aliens4friends/aliens4friends-pool/userland/base-files/3.0.14-r89/base-files-3.0.14-r89-083db427.final.spdx | 

if [ -z "$1" ]; then
    echo "Converts an Aliens4Friends SPDX Tag/Value File to a CycloneDX JSON SBOM"
    echo "Usage: $0 <.final.spdx file>"
    exit 1
fi


# Convert SPDX Tag/Value to SPDX JSON
docker build --tag leda/spdx-tools --build-arg TOOLS_JAVA_VERSION=1.1.6 https://github.com/spdx/tools-java.git#v1.1.6

mkdir -p ./output

function tv2json() {
    local FILE=$1
    BASENAME=$(basename "${FILE}" ".final.spdx")
    BASEPATH=$(dirname "${FILE}")
    REALPATH=$(realpath "${BASEPATH}")
    echo "Converting Tag/Value SPDX format to JSON SPDX format"
    echo "- File: ${FILE}"
    echo "- Base name: ${BASENAME}"
    echo "- Base path: ${BASEPATH}"
    echo "- Real path: ${REALPATH}"
    C_INPUT="/input/${BASENAME}.final.spdx"
    C_OUTPUT="/output/${BASENAME}.spdx.json"
    echo "- Input: ${C_INPUT}"
    echo "- Output: ${C_OUTPUT}"
    docker run \
        --rm \
        --volume "${REALPATH}:/input" \
        --volume "$(pwd)/output/:/output" \
        leda/spdx-tools \
        Convert \
        "${C_INPUT}" \
        "${C_OUTPUT}" \
        Tag \
        JSON
}

function json2cdx() {
    local BASENAME="$1"
    echo "Converting SPDX JSON format to CycloneDX JSON format"
    echo "- Base name: ${BASENAME}"
    C_INPUT="/output/${BASENAME}.spdx.json"
    C_OUTPUT="/output/${BASENAME}.cyclonedx.json"
    echo "- Input: ${C_INPUT}"
    echo "- Output: ${C_OUTPUT}"
    docker run \
        --rm \
        --volume "$(pwd)/output/:/output" \
        cyclonedx/cyclonedx-cli \
            convert \
            --input-format spdxjson \
            --output-format json \
            --input-file "/output/${BASENAME}.spdx.json" \
            --output-file "/output/${BASENAME}.cyclonedx.json"
}

INPUTFILE="$1"
BASENAME=$(basename "${FILE}" ".final.spdx")
tv2json "${INPUTFILE}" "${BASENAME}"
json2cdx "${BASENAME}"

