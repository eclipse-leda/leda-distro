# Dependency Track

## Starting the server

```shell
docker compose up -d
# Open browser at http://localhost:8080/
```

## Convert Yocto SPDX to CycloneDX

Yocto only supports SPDX, DependencyTrack only support CycloneDX.
Hence, the files need to be converted using the cyclonedx-cli tool:

```shell
docker run cyclonedx/cyclonedx-cli convert --input-format spdxjson --output-format json < $SPDX_JSON_FILE > $CYCLONEDX_JSON_FILE
```

