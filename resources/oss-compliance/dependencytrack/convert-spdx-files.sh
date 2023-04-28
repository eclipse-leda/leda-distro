#!/bin/bash

if [ -z ${1} ]; then
    echo "Usage: $0 <BITBAKE_BUILD_DIR>"
    exit 1
fi

BUILD_DIR="$(realpath ${1})"
OUTPUT_DIR="${BUILD_DIR}/tmp/deploy/cyclonedx"

mkdir -p "${OUTPUT_DIR}"

echo "Using build dir : ${BUILD_DIR}"
echo "Using output dir: ${OUTPUT_DIR}"

while IFS= read -r -d '' filename
do
    INPUT_FILE="${filename}"
    OUTPUT_FILENAME="$(basename ${INPUT_FILE/".spdx.json"/".cyclonedx.xml"})"
    OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_FILENAME}"
    echo "Input: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    cat ${INPUT_FILE} | docker run -i cyclonedx/cyclonedx-cli convert --input-format spdxjson --output-format xml > ${OUTPUT_FILE}
    curl -X "POST" "http://localhost:8081/api/v1/bom" \
     -H 'Content-Type: multipart/form-data' \
     -H "X-Api-Key: bbYtyccxaa4iqDtRysUY6uuwaEGziPHu" \
     -F "projectName=leda" \
     -F "projectVersion=0.1.0-git-main" \
     -F "bom=@${OUTPUT_FILE}"
done < <(find ${BUILD_DIR}/tmp/deploy/spdx -type f -name '*.json' -print0)
