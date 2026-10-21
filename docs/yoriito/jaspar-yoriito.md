# Yoriito integration

This document is the working integration plan and the Leda-specific technical
guide for future maintainers. It records decisions, implementation steps,
verification, and the instructions needed for a first user smoke test. It is
not intended to replace the upstream Yoriito documentation.

## Purpose

Eclipse Leda is an incubator for integrating external software related to
software-defined vehicles. Leda will showcase both Yoriito and the Eclipse
Kuksa Databroker so users can experiment with two implementations of a VSS API
and compare them when making architectural decisions.

The projects have related responsibilities, including providing a VSS server,
but serve different emphases. Yoriito offers more APIs and broader use cases.
The Eclipse Kuksa Databroker focuses on a lightweight embedded use case and
vehicle-signal access with functional-safety requirements, including legacy
bus communication and SOME/IP integration as first-class concerns.

The initial Leda integration should provide a working native example, not
merely installable binaries: the server, CLI, configuration, and example VSS
and VSPEC data must be available and usable on the image.

## Agreed scope and decisions

- **Pull Request:** https://github.com/eclipse-leda/leda-distro/pull/190 (Draft)
- **Source:** use the Leda-maintained fork at
  <https://github.com/mikehaller/meta-yoriito>, forked from
  <https://github.com/yoriito/meta-yoriito>. Leda may need to patch the layer
  to support its current Yocto release.
- **Fork branch:** use `leda-integration` based on upstream `main` for the
  Wrynose compatibility work; follow the branch without a fixed revision
  during active integration.
- **Yocto release:** target Wrynose, which is the release currently used by
  this repository. The upstream layer currently supports Scarthgap.
- **First target:** QEMU x86-64.
- **Image scope:** install Yoriito in `sdv-image-full`, not in the minimal or
  rescue images. `sdv-image-all` is an aggregate build target that builds
  `sdv-image-full`, `sdv-image-minimal`, `sdv-image-rescue`, and `sdv-image-data`;
  it is useful for verification but is not itself the image to modify.
- **First deployment:** install and run Yoriito natively on the image. Container
  support is a later phase.
- **Boot behavior:** integrate a systemd service, enable it by default, and
  start the Yoriito server/daemon automatically at boot.
- **Included runtime:** server/daemon, CLI tools, configuration, and a working
  example VSS/VSPEC dataset.
- **First manual verification:** boot the image with `scripts/leda` and use the
  simplest working `curl` check from either the host or guest to confirm that
  the HTTP API is available. The intended automated smoke test should
  eventually be part of `sdv-health` in the separate `leda-utils` repository.
- **Usage audience:** users who know the basics of VSS and Linux commands, and
  want to try the Leda integration. Explain the Leda-specific service,
  binaries, ports, paths, example signal names, and CLI commands. Refer readers
  to the upstream Yoriito documentation for general product documentation.

## Integration plan

### 1. Port and add the layer

- [x] Create the `leda-integration` branch in the Leda fork, based on upstream
  `main`, for Wrynose compatibility work.
- [x] Port the `meta-yoriito` layer from Scarthgap to Wrynose, keeping changes
  isolated and suitable for contribution upstream where practical.
- [x] Add the layer to the KAS configuration on the `leda-integration` branch
  without a fixed commit, so active porting changes are picked up continuously.
- [x] Build the Yoriito VSS and Kura components and resolve the initial
  Wrynose compatibility issues.

### 2. Install and run natively

- [x] Add a dedicated `packagegroup-sdv-yoriito` package group in the
  `meta-leda/meta-leda-components/recipes-sdv/yoriito/` for the server, CLI,
  configuration, and example data, depending on the upstream
  `packagegroup-yoriito-core`. Keep Yoriito out of the generic
  `packagegroup-sdv-additions`.
- [x] Include the package group in `sdv-image-full` only; do not add it to the
  minimal or rescue images.
- [x] Use the upstream Kura systemd unit, which is enabled by default, and
  verify it starts successfully on the image.
- [x] Ensure the example configuration and VSS/VSPEC data work with the
  installed server.
- [x] Add the upstream `vshot` VISS CLI/TUI through a Leda recipe and install
  it with the Yoriito package group.
- [x] Build `sdv-image-full` and verify the `vshot` help output using the
  target Python environment.
- [x] Exercise `vshot` against the running Kura service to verify signal
  reads, writes, subscriptions, and the interactive TUI.

### 3. Verify the first user workflow

- [x] Build `sdv-image-all` for `leda-qemux86-64` using the repository's KAS
  workflow. This aggregate target also builds the full image containing
  Yoriito.
- [x] Start the image with `scripts/leda`.
- [x] Verify the systemd unit is enabled, starts at boot, and reports a healthy
  running service.
- [x] Verify with the simplest working `curl` request, from the host or guest,
  that the HTTP API is reachable and responds as expected. Note: tested with "vshot" instead of curl.
- [x] Exercise the Yoriito CLI to query, set, get, and subscribe to example
  signals, recording the exact commands and expected output for the Usage
  section. Note: Used "vshot".
- [x] Plan a follow-up `sdv-health` check in the separate `leda-utils`
  repository so service/API availability is covered by the Leda health check.

### 4. Add containerized deployment (later phase)

- [x] Decide which Yoriito server components should run in containers and how
  users select either the native or containerized deployment. The deployments
  are expected to be alternatives, not active side-by-side in one image.
- [x] Add the required images to Leda's airgap container workflow so they are
  available from the data partition.
- [x] Decide whether to extend
  `packagegroup-sdv-airgap-containers` and
  `packagegroup-sdv-additions`, or introduce a separate package group.
- [x] Document how to select, start, inspect, and troubleshoot the
  containerized deployment.
- [ ] Verify container-mode reads, writes, subscriptions, and TUI operation
  on the other supported machines (QEMU ARM64 and Raspberry Pi).

## Usage guide

See [Yoriito Kura at runtime on Eclipse Leda](jaspar-yoriito-runtime.md) for
the tested `Vehicle.Speed` read/write example, source-verified subscription
syntax, service management, ports, installed commands, and troubleshooting.
Runtime reads, writes, subscriptions, and TUI operation have been confirmed
by the maintainer on QEMU; no HTTP endpoint has been verified or added.

### Health-check follow-up for `leda-utils`

Implement this in the separate `leda-utils` repository, then update the
`leda-utils_git.bb` source revision in `meta-leda` after upstream review:

1. Gate the Yoriito section on its installation so minimal/rescue images
   without Yoriito remain healthy. Missing `vshot` when Yoriito is selected
   must be reported as a failure, not skipped.
2. For native mode, check `kura.service` with the existing service-check
   helper. For container mode, check the Kanto `kura` container instead;
   a deliberately disabled native service is not a container-mode failure.
3. Check both loopback gRPC listeners, `50052` and `50053`. Port checks alone
   are diagnostics, not proof of a working VISS API.
4. Run `vshot get-current Vehicle.Speed` with a bounded timeout (for example,
   5 seconds), capture its exit status and stderr, and require the expected
   `Vehicle.Speed` path in the response. Exit status alone is insufficient
   to establish that the response contains the requested signal. An unset
   datapoint is valid.
5. Report timeout, connection failure, missing command, invalid response,
   or failed service/container explicitly through the existing health output.
   Do not write signal values, start services, or create a persistent
   subscription as part of a health check.
6. Cover valid/unset responses, empty output with exit status zero, RPC
   errors, timeout, either missing listener, native-service failure, and
   the not-installed and container-mode cases with mocked commands.

This is a planned upstream change, not an installed health check. The pinned
health script currently checks services, sockets, and containers but has no
Yoriito API probe.

### Container implementation constraints

The requested scope is Kura only, using an enabled Kanto deployment manifest
and the existing airgap image archive workflow. Native remains the default;
the build-time container-mode selection prevents native service startup,
installs the active manifest, and includes the corresponding archive on the
data partition. Both modes retain `vshot` and the example data.

Use host networking for the pinned loopback-only server and run without
privileged mode. Package configuration and VSS data into the OCI image:
the installed Kanto version does not expose read-only bind mounts, so do
not grant writable host configuration mounts. Verify the container
entry point, architecture support, license, size, and a reproducible image
reference before adding the archive recipe; upstream's development-container
CI is not evidence of a supported Kura runtime image.

The maintainer selected building an OCI image from Leda's existing Kura
recipe. `kas/yoriito-container.yaml` selects the alternative deployment;
native remains the default. Dedicated `sdv-container-kura` and
`sdv-kura-deployment` packages are installed only in the container-mode data
image. The generic additions and airgap example package groups are unchanged.
The Kura archive and its host-side installer are always included for this
local-only image reference, even without the optional `airgap-containers`
feature.

Validation: the OCI/archive/descriptor packages and container-mode
`sdv-image-all` build passed on QEMU x86-64. An isolated Docker run verified
Kura startup and both loopback listeners. A fresh QEMU boot confirmed native
Kura is disabled, the archive imports successfully, and Kanto auto-deploys
the `kura` container in Running state. A second fresh QEMU boot verified a
`vshot set-current Vehicle.Speed 123` followed by `get-current` returns a
datapoint containing `float: 123` from the container.
The OCI layout is about 5.5 MiB compressed; the Docker-compatible archive
is about 13 MiB, with about 26 MiB of unpacked image content. Configuration
checks also verified native service enablement and archive/installer
inclusion when container mode is selected without `airgap-containers`.
After the final rebuild, another snapshot boot repeated the read/write
check successfully. The guest reported about 404 MiB free on `/` and
1.9 GiB free on `/data`; the installed Kura archive occupied 12.5 MiB.

### Usage documentation checklist

The user-facing Usage section should document the tested Leda workflow and
include:

- how to start the server and check, restart, and stop its systemd service;
- the installed binary and configuration/data locations;
- the gRPC endpoints, ports, and a working `vshot` example (there is no
  implemented HTTP controller in the pinned source);
- the CLI tool names and exact commands to query, set, get, and subscribe to
  named example vehicle signals;
- where service logs are available and how to retrieve them; and
- common integration-specific problems and troubleshooting steps.

Use verified values from the built image; do not guess service names, ports,
paths, signal names, or command syntax. Link to the upstream Yoriito
documentation for topics beyond the Leda integration and smoke test.

## Confirmed upstream details

The following upstream details have been confirmed from the Yoriito fork:

- `packagegroup-yoriito-core` brings in `yoriito-viss-server`,
  `yoriito-viss-client`, `yoriito-vss`, and the Yoriito vehicle API libraries.
- The server is provided by Kura. Its recipe installs and enables
  `kura.service`, which starts `/usr/bin/kura` with
  `/etc/yoriito/viss/config.yml`.
- The VSS recipe installs `vss.json` under `/etc/yoriito/viss/` and a CSV
  artifact under `/usr/share/yoriito/`.
- Leda's `vshot` recipe builds the Python client from the same Kura revision
  used by the upstream recipes. It installs a `vshot` command with
  `get-current`, `get-target`, `set-current`, `set-target`, subscription, and
  unsubscription subcommands. `vshot -i` starts its command REPL, and
  `vshot tui` starts the interactive terminal UI. The client source defaults
  to `localhost` and ports `50052`/`50053`.
- The QEMU full-image build includes `vshot`; its CLI help was smoke-tested
  against the target rootfs. The recipe carries a small Python 3.14
  compatibility patch for `distutils.util.strtobool`, which was removed from
  the standard library.
- The remote `leda-integration` branch is at
  `da3825239bdae9d4bdec6da69959a9ac7a040a85`; the local and remote branches
  point to the same commit. The Wrynose port declares compatibility and
  updates recipes for BitBake's `UNPACKDIR` layout.
- The layer depends on `rust-bin-layer`; the current `meta-rust-bin` master
  metadata also declares Wrynose compatibility. KAS currently follows its
  `master` branch without a commit pin.
- The initial KAS checkout failure came from an existing shallow local clone
  whose fetch refspec tracked only `main`. KAS did not fetch the newly
  configured branch when given the short branch name. Configuring
  `refs/heads/leda-integration` makes KAS fetch that exact branch; this was
  verified with `kas checkout kas/leda-qemux86-64.yaml`.
- `kas build kas/leda-qemux86-64.yaml --target yoriito-vss` completed
  successfully. The Kura build initially failed the `buildpaths` QA check,
  so Leda's `kura_git.bbappend` remaps Rust source paths with
  `--remap-path-prefix=${WORKDIR}=.`. After that change,
  `kas build kas/leda-qemux86-64.yaml --target kura` also completed
  successfully. The first `kura-client` build exposed a missing `<cstdint>`
  include in the upstream `timebased_filter.h`. Leda carries a temporary
  patch through `yoriito-common-library_git.bbappend`; BitBake's forced
  `do_patch` task confirmed the append applies the patch. The client build
  passed with the same header fix before the patch was moved into `meta-leda`.
  The source fix is published on
  [`mikehaller/yoriito-vehicle-api:fix-timebased-filter-cstdint`](https://github.com/mikehaller/yoriito-vehicle-api/tree/fix-timebased-filter-cstdint)
  for a PR to the upstream `yoriito/vehicle-api` repository. A separate
  layer-level patch branch is published on
  [`mikehaller/meta-yoriito:fix-timebased-filter-header`](https://github.com/mikehaller/meta-yoriito/tree/fix-timebased-filter-header).

## Building containerized Yoriito

You can decide whether to build the Leda image `sdv-image-all` with Yoriito Kura installed
as native system binary (systemd service) and bake it into the disk image -- or if you want to
deploy it at runtime (on startup) as a container.

For the Leda Quickstart image, the container images are pre-installed on the data partition by default,
to minimize startup problems when no internet is available (air-gap installation).

Containers are updatable at runtime using OTA and cloud connector, or manually by editing JSON-based
deployment manifest files and retriggering the container-management service to pull and restart the updated containers.

```
# Build and install Yoriito (Kura only) as container instead of native installation:
kas build kas/leda-qemux86-64.yaml:kas/yoriito-container.yaml

# Test it on qemu:
kas shell kas/leda-qemux86-64.yaml:kas/yoriito-container.yaml \
  -c 'runqemu slirp ovmf kvm nographic sdv-image-all'
```

## Open questions

Still to be confirmed during implementation and image testing:

- Which example vehicle-signal names should be used? -> "Vehicle.Speed" is good enough
- Do the Vshot default ports match the deployed Kura configuration, and do
  its read/write/subscribe commands work against the running service?
  -> Yes, works out of the box, already tested on Leda via runqemu and sdv-image-all
- The pinned Kura source implements loopback gRPC endpoints, not an HTTP
  controller. Use `vshot`; there is no verified HTTP URL to document.
- Which container runtime and Yoriito images should the later airgap phase
  support, and how should users select one deployment mode? -> kura server as container, kanto deployment manifest prepared, enabled and auto-deployed
