# Dependency Track

## Starting the server

```shell
docker compose up -d
# Open browser at http://localhost:8080/
```


## Convert Yocto SPDX to CycloneDX

Yocto only supports SPDX, DependencyTrack only support CycloneDX.
Hence, the files need to be converted using the cyclonedx-cli tool:

The BitBake build must be run with enabled `spdx.yaml` to generate the SPDX files.

```shell
kas build kas/leda-qemux86-64.yaml:kas/oss-compliance/spdx.yaml:kas/mirrors.yaml
```

To convert a single SPDX file to a CycloneDX file:

```shell
docker run cyclonedx/cyclonedx-cli convert --input-format spdxjson --output-format json < $SPDX_JSON_FILE > $CYCLONEDX_JSON_FILE
```

To convert many files in batch, use the sbom-converter.py script or the Dockerfile.sbomconverter to convert in batch.

Build the container:

```shell
./run-docker.sh
```

find /workspaces/leda-distro-fork/resources/oss-compliance/aliens4friends/aliens4friends-pool/userland -type l -name "*.final.spdx" | parallel ./a4f-to-cyclonedx.sh {}

# find /dump -type f -name '*.xml' | parallel -j8 java -jar ProcessFile.jar {}
