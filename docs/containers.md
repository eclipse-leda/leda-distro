# Container build workflows

Leda has separate mechanisms for running, deploying, and building containers.
They serve different purposes and are not all enabled by the default image.

## Overview

- Eclipse Kanto: supports OCI-compliant container images (e.g. Docker, Podman), container management for resource-constrained devices, optimized for standardized OTA and Digital Twin use cases of edge devices
- Northstar: proprietary format for even more resource-constrained devices where the container images are pre-baked for specific device configurations

## Runtime and deployment

- `containerd` stores and runs OCI images. Kanto manifests name the
  `io.containerd.runc.v2` shim; Leda configures that shim to execute `/usr/bin/crun`.
  `crun` is the OCI runtime, not a second container manager.
- Eclipse Kanto Container Management (`container-management`) manages containers
  through containerd.
- Kanto Auto Deployer (`kanto-auto-deployer`) reads the JSON manifests installed
  under `/data/var/containers/manifests` and deploys them at startup. The systemd
  service is enabled in the standard images.
- `sdv-core-containers` and `sdv-example-containers` install deployment manifests;
  they do not contain the referenced image layers.

### Runtime data and command flow

The following shows the default airgap-enabled image at runtime. The `data`
partition is mounted at `/data`; it contains the Kanto manifests, preloaded OCI
archives, and containerd's persistent store.

```mermaid
flowchart TD
    subgraph ROOT["Leda root filesystem (active root_a or root_b)"]
        SYSTEMD["systemd"]
        KAD["Kanto Auto Deployer<br/>kanto-auto-deployer"]
        CM["Eclipse Kanto<br/>Container Management"]
        CONTAINERD["containerd service"]
        CRUN["crun<br/>OCI runtime"]
        BROKER["Databroker container<br/>0.7.1"]
    end

    subgraph DATA["Separate data partition, mounted at /data"]
        ARCHIVES["Preloaded OCI archives<br/>/data/var/containers/images"]
        MANIFESTS["Kanto JSON manifests<br/>/data/var/containers/manifests"]
        STORE["containerd persistent store<br/>/data/var/containerd"]
    end

    IMPORTER["airgap-container-installer<br/>ctr image import"]

    SYSTEMD -->|"starts after data.mount and containerd"| IMPORTER
    SYSTEMD -->|"starts after data.mount"| CM
    SYSTEMD -->|"starts after container-management"| KAD

    ARCHIVES -->|"reads tar archives"| IMPORTER
    IMPORTER -->|"imports into kanto-cm namespace"| CONTAINERD
    CONTAINERD <-->|"reads/writes images and container state"| STORE

    MANIFESTS -->|"reads deployment descriptors"| KAD
    KAD -->|"MQTT deployment commands"| CM
    CM -->|"creates and manages containers"| CONTAINERD
    CONTAINERD -->|"io.containerd.runc.v2 shim configured for crun"| CRUN
    CRUN -->|"runs OCI workload"| BROKER
```

The installer is ordered after both `containerd.service` and `data.mount`, and
before `container-management.service`. Container Management also waits for the
data mount. Auto Deployer starts after Container Management and reads manifests
from the mounted data partition, then submits deployment commands over Kanto's
MQTT interface. Imported images and deployed-container state are kept by
containerd under `/data/var/containerd`.

The default distro enables `airgap-containers`. Its image archives are installed
into `sdv-image-data` under `/var/containers/images`, which is mounted at
`/data/var/containers/images` on the running system. The
`airgap-container-installer` service imports those archives into containerd's
`kanto-cm` namespace before `container-management` starts. The core Databroker
manifest and its cached image both use `ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.1`.
The `databroker-cli` is a native Leda package, not a container; the distro pins
both native recipes to 0.7.1.

In airgap mode, the example `feedergps` and `node-red` manifests are not installed
because their images are not in the default airgap package group. With the
`airgap-containers` distro feature removed, these examples are deployed normally
and may require registry access.

## Build an application package with BitBake

This is the normal Yocto source-to-package flow. It builds the target binary and
package; it does not create or deploy a container image.

```mermaid
flowchart TD
    MAINTAINER@{ shape: "person", label: "Leda Maintainer" }
    UPSTREAM["Upstream source<br/>Git or release archive"]
    RECIPE["Application BitBake recipe<br/>SRC_URI + pinned SRCREV"]
    FETCH["do_fetch / do_unpack"]
    BUILD["do_configure / do_compile"]
    INSTALL["do_install"]
    PACKAGE["Target package<br/>binary + runtime files"]
    FEED["BitBake package feed / sysroot"]

    MAINTAINER -->|"selects source, reviews and pins revision"| RECIPE
    UPSTREAM --> FETCH
    RECIPE --> FETCH
    FETCH --> BUILD
    BUILD --> INSTALL
    INSTALL --> PACKAGE
    PACKAGE --> FEED
```

Add or update the application recipe in
`meta-leda-components/recipes-sdv/<component>/`. Pin `SRC_URI` and `SRCREV` (or
use a versioned release archive), declare dependencies and license information,
and install the target executable through `do_install`. Review and test the
source/package change before using that package in an OCI image.

```sh
kas shell kas/leda-qemux86-64.yaml -c 'bitbake <application-recipe>'
```

For example, the Databroker application package target is `databroker` (the
native CLI is a separate target, `databroker-cli`):

```sh
kas shell kas/leda-qemux86-64.yaml -c 'bitbake databroker'
```

## Create an OCI image from a BitBake package

This flow starts with a target package built by BitBake above. The container
recipe assembles that package into an OCI image; it is separate from the recipe
that originally built the application package.

```mermaid
flowchart TD
    MAINTAINER@{ shape: "person", label: "Leda Maintainer" }
    PACKAGE["Previously built target package"]
    RECIPE["OCI image recipe<br/>meta-leda-distro-container"]
    ROOTFS["Container root filesystem<br/>IMAGE_INSTALL"]
    OCI["image-oci task"]
    TAR["Machine-specific OCI archive<br/>DEPLOY_DIR_IMAGE"]
    BUNDLE["Optional sdv-container-images bundle"]
    MANIFEST["Maintainer-authored Kanto JSON<br/>image reference/tag + runtime config"]
    MANIFEST_RECIPE["sdv-core-containers or<br/>sdv-example-containers"]
    DATA["sdv-image-data<br/>separate /data partition"]
    FINAL["sdv-image-all<br/>bootable disk image"]

    MAINTAINER -->|"maintains recipe, entrypoint and OCI_IMAGE_*"| RECIPE
    PACKAGE -->|"IMAGE_INSTALL resolves package"| ROOTFS
    RECIPE --> ROOTFS
    ROOTFS --> OCI
    OCI --> TAR
    MAINTAINER -->|"adds target to CONTAINER_IMAGES if bundling"| BUNDLE
    TAR -.-> BUNDLE
    MAINTAINER -->|"authors manifest; validates ref/tag"| MANIFEST
    MANIFEST -->|"SRC_URI + do_install"| MANIFEST_RECIPE
    MANIFEST_RECIPE --> DATA
    BUNDLE -.->|"requires explicit integration;<br/>not in default image"| DATA
    DATA --> FINAL
    MAINTAINER -->|"reviews package/image/manifest and runs build"| FINAL
```

Create the OCI recipe under
`meta-leda-distro-container/recipes-sdv/sdv-containers/`. Inherit
`../images/sdv-image-container.bb`, add the application package to
`IMAGE_INSTALL`, and set `OCI_IMAGE_TAG`, entrypoint, ports and environment as
needed. Build one image or the existing bundle with:

```sh
kas shell kas/leda-qemux86-64.yaml -c 'bitbake <container-image-recipe>'
kas shell kas/leda-qemux86-64.yaml -c 'bitbake sdv-container-images'
```

The Databroker OCI recipe target is `databroker-container` (not
`sdv-kuksa-databroker-container`). Build it with:

```sh
kas shell kas/leda-qemux86-64.yaml -c 'bitbake databroker-container'
```

This builds a local Databroker OCI image. The machine-specific OCI tar is emitted
under `build/tmp/deploy/images/<machine>/`.
`sdv-container-images` bundles the image targets named in `CONTAINER_IMAGES`,
but that bundle is not included in default `sdv-image-all`. To deploy a
locally-built OCI image from the standard disk image, maintainers must integrate
its archive into `sdv-image-data`.

The Kanto JSON is a separate deployment descriptor, not generated from the OCI
recipe. Add or update it under
`meta-leda-components/recipes-sdv/eclipse-leda/kanto-containers/`, then update
the appropriate `sdv-core-containers.bb` or `sdv-example-containers.bb`
`SRC_URI`, `do_install`, and `FILES` entries. For an airgap image, include the
matching archive and ensure the manifest uses the exact image reference/tag.

## Deploy a prebuilt OCI image

Use this path when the OCI image is built elsewhere and Leda only needs to
include and deploy it. The default airgap configuration uses a remote registry
at image-build time. A pre-existing local OCI archive can also be supplied to
the cache recipe instead. In either case the target device imports the cached
archive; it does not need to pull the image at startup.

```mermaid
flowchart TD
    MAINTAINER@{ shape: "person", label: "Leda Maintainer" }
    UPSTREAM["Upstream project publishes OCI image"]
    REGISTRY["Remote OCI registry"]
    LOCAL["Local prebuilt OCI archive<br/>with matching image tag"]
    RECIPE["sdv-container-cache recipe<br/>SDV_IMAGE_REF + SDV_IMAGE_TAG"]
    SKOPEO["Build-time skopeo fetch<br/>(remote source)"]
    ARCHIVE["Versioned OCI archive<br/>in image package"]
    MANIFEST["Maintainer-authored Kanto JSON"]
    MANIFEST_RECIPE["sdv-core-containers or<br/>sdv-example-containers"]
    DATA["sdv-image-data<br/>/data partition"]
    FINAL["sdv-image-all"]
    IMPORT["airgap-container-installer<br/>at boot"]
    CTRD["containerd<br/>namespace kanto-cm"]
    KAD["kanto-auto-deployer<br/>at boot"]
    CM["container-management"]
    RUNTIME["containerd OCI runtime<br/>crun"]
    APP["Running container"]

    MAINTAINER -->|"reviews upstream release and pins ref/tag"| RECIPE
    UPSTREAM --> REGISTRY
    REGISTRY --> SKOPEO
    RECIPE --> SKOPEO
    SKOPEO --> ARCHIVE
    LOCAL -->|"pre-staged archive as recipe download"| ARCHIVE
    MAINTAINER -->|"authors manifest with identical ref/tag"| MANIFEST
    MANIFEST -->|"SRC_URI + do_install"| MANIFEST_RECIPE
    MANIFEST_RECIPE --> DATA
    ARCHIVE -->|"packagegroup-sdv-airgap-containers"| DATA
    DATA --> FINAL
    MAINTAINER -->|"reviews pairing and builds image"| FINAL
    FINAL -->|"boot; data mounted at /data"| IMPORT
    FINAL -->|"services start in dependency order"| KAD
    DATA -->|"OCI archives"| IMPORT
    DATA -->|"JSON manifests"| KAD
    IMPORT -->|"ctr image import"| CTRD
    KAD -->|"MQTT deployment command"| CM
    CM -->|"create/start/stop"| CTRD
    CTRD --> RUNTIME
    RUNTIME --> APP
```

Add or update a cache recipe in
`meta-leda-components/recipes-sdv/sdv-containers/`, inheriting
`sdv-container-cache`. Pin `SDV_IMAGE_REF` and `SDV_IMAGE_TAG`; `skopeo` fetches
that image during a connected build. The standard package group,
`packagegroup-sdv-airgap-containers`, selects cached images for `sdv-image-data`.
For a pre-staged local archive, supply the archive at the recipe's expected
`SDV_DL_FILE` in `DL_DIR` and ensure its embedded image tag matches the recipe.

Example targeted build:

```sh
kas shell kas/leda-qemux86-64.yaml -c 'bitbake sdv-kuksa-val-databroker'
```

Update the matching Kanto manifest under
`meta-leda-components/recipes-sdv/eclipse-leda/kanto-containers/`; maintainers
must verify the image name and tag exactly match the cache recipe and only
activate manifests for images included in the airgap package group. Then build
and boot the final image:

```sh
kas build kas/leda-qemux86-64.yaml
scripts/leda
```

Verify that the data partition and deployment services started successfully,
and that the Databroker container was deployed only once. The commands below
are run in the booted Leda system. Commit the `meta-leda` changes and update the
pinned layer revision in `kas/common-wrynose.yaml` for a reproducible downstream
build.

`sdv-image-all` composes the full, minimal, rescue, and data images. The data
image is written to the separate partition used for manifests, blueprints, and
cached image archives. `scripts/leda` starts the resulting QEMU image; it does
not build or pull containers at startup when the airgap path is used.

### Verify deployment with KantUI

KantUI (`kantui`) is a terminal TUI for human users to inspect and manage
containers through Kanto Container Management. It is included in
`sdv-image-full` via `packagegroup-sdv-additions`. After booting the image with
`scripts/leda`, log in to the running Leda system and start it:

```sh
kantui
```

In KantUI, inspect the container list and select the Databroker container.
Confirm that its image is `ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.1` and
that its state is running. This shows that Container Management has a deployed
container using the expected image and that it is currently started. In a
connected deployment, the image may have been pulled from the registry; in the
default airgap deployment, the startup installer imports the matching cached
image archive before Auto Deployer creates and starts the container.

Check mount and service status with `systemctl`:

```sh
systemctl status data.mount containerd.service airgap-container-installer.service \
    container-management.service kanto-auto-deployer.service
```

Use the Kanto and containerd command-line tools to check the deployed
container's state, its image, and whether it has a running task:

```sh
kanto-cm list
ctr --namespace kanto-cm images list
ctr --namespace kanto-cm containers list
ctr --namespace kanto-cm tasks list
```

In the `kanto-cm list` output, confirm there is a single Databroker deployment
and that it is running with the 0.7.1 image. In `ctr` output, verify that the
image is present in the `kanto-cm` namespace, the container has been created,
and its task is running. The airgap image is imported during startup; a
connected Kanto deployment may instead pull it from its configured registry.

Inspect this boot's service logs for importer messages and Auto Deployer
deployment results:

```sh
journalctl --boot -u airgap-container-installer.service \
    -u container-management.service -u kanto-auto-deployer.service \
    --no-pager
```

KantUI, `kanto-cm`, and `ctr` show current state rather than a history of
startup events; use `systemctl status` and `journalctl` to verify service
startup and diagnose failures.
