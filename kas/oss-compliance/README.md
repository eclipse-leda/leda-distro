# Open Source Compliance Tooling and Integration

## Tinfoilhat

The Eclipse Oniro project provides an integration for IP compliance auditing.
The tool is called *tinfoilhat` and allows to parse a BitBake build output.

```shell
# First: Build with generation of source mirrors.
# Do NOT include remote mirrors (mirrors.yaml)
kas build kas/leda-qemux86-64.yaml:kas/oss-compliance/tinfoilhat.yaml

# Second: Run tinfoilhat
cd resources/oniro
./run-docker.sh
```

Generated output is in `${WORKSPACE}/build/tmp/deploy/tinfoilhat`

## Dependency Track

To upload Yocto-generated SPDX information to Dependency Track, an additional meta-layer `meta-dependencytrack` needs to be used.
It creates the CycloneDX format out of the CVE information.

Pros:

- Integration with Dependency Track
- Audit Vulnerabilities

Cons:

- Only supports components and CVE information, but no actual dependencies or version

Usage: Build with uploading of SBOM to local dependencytrack service.

```shell
pushd resources/dependencytrack
docker compose up -d
# Login to http://localhost:8080/
# First use:
# - Change password of dependencytrack admin user
# - Retrieve API Key via Settings > Teams > Automation > API-Key
# - Create project, note down ProjectID
popd

# Edit kas/dependencytrack.yaml
# - Update API-Key
# - Update Project ID
kas build kas/leda-qemux86-64.yaml:kas/oss-compliance/dependencytrack.yaml
```

## Double-Open Project

Note: `meta-doubleopen` currently does not support Yocto Kirkstone release and cannot be used.
