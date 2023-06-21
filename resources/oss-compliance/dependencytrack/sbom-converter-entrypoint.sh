#!/bin/sh
#
# Docker Container
#
# Input:
#  - BitBake build/ directory with enabled create-spdx bbclass
#  - Mounted to /build in container as volume
#  - Contains /build/tmp/deploy/spdx/<MACHINE>/[runtime|recipes|packages]/*.json in SPDX format
#
# Output:
# - Converted all SPDX .json files to CycloneDX .json files
# - Mounted to /output
# - Files generated in /output/cyclonedx/<MACHINE>/[runtime|recipes|packages]
# - A single CycloneDX JSON file with all individual files merged into a big one, in /output/cyclonedx.json
#
# python3 ./.github/workflow-scripts/sbom-converter.py ./build/tmp/deploy/spdx/qemux86-64/runtime ./output/cyclonedx-sbom-qemux86/runtime
# python3 ./.github/workflow-scripts/sbom-converter.py ./build/tmp/deploy/spdx/qemux86-64/recipes ./output/cyclonedx-sbom-qemux86/recipes    
# python3 ./.github/workflow-scripts/sbom-converter.py ./build/tmp/deploy/spdx/qemux86-64/packages ./output/cyclonedx-sbom-qemux86/packages    

echo "SBOM SPDX-to-CycloneDX Converter"

MACHINES=$(ls /build/tmp/deploy/spdx/)

for MACHINE in ${MACHINES[@]};
do
    echo "Converting for ${MACHINE}..."
    echo "- Runtime"
    python3 /sbom-converter.py /build/tmp/deploy/spdx/${MACHINE}/runtime /output/cyclonedx/${MACHINE}/runtime
    echo "- Recipes"
    python3 /sbom-converter.py /build/tmp/deploy/spdx/${MACHINE}/recipes /output/cyclonedx/${MACHINE}/recipes
    echo "- Packages"
    python3 /sbom-converter.py /build/tmp/deploy/spdx/${MACHINE}/packages /output/cyclonedx/${MACHINE}/packages
    echo "- Merging output"
    /cyclonedx add files --base-path /build/tmp/deploy/spdx/${MACHINE} --input-format=json --output-file leda-${MACHINE}.sbom.cyclonedx.json --output-format=json
done

echo "Done."