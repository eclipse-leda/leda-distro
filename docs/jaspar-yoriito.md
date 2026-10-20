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
- **Fork branch:** create `leda-integration` based on upstream `main` for the
  Wrynose compatibility work; pin the KAS layer to that branch's resulting
  revision.
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
- [ ] Use the upstream Kura systemd unit, which is enabled by default, and
  verify it starts successfully on the image.
- [ ] Ensure the example configuration and VSS/VSPEC data work with the
  installed server.
- [x] Add the upstream `vshot` VISS CLI/TUI through a Leda recipe and install
  it with the Yoriito package group.
- [x] Build `sdv-image-full` and verify the `vshot` help output using the
  target Python environment.
- [ ] Exercise `vshot` against the running Kura service to verify signal
  reads, writes, subscriptions, and the interactive TUI.

### 3. Verify the first user workflow

- [ ] Build `sdv-image-all` for `leda-qemux86-64` using the repository's KAS
  workflow. This aggregate target also builds the full image containing
  Yoriito.
- [ ] Start the image with `scripts/leda`.
- [ ] Verify the systemd unit is enabled, starts at boot, and reports a healthy
  running service.
- [ ] Verify with the simplest working `curl` request, from the host or guest,
  that the HTTP API is reachable and responds as expected.
- [ ] Exercise the Yoriito CLI to query, set, get, and subscribe to example
  signals, recording the exact commands and expected output for the Usage
  section.
- [ ] Plan a follow-up `sdv-health` check in the separate `leda-utils`
  repository so service/API availability is covered by the Leda health check.

### 4. Add containerized deployment (later phase)

- [ ] Decide which Yoriito server components should run in containers and how
  users select either the native or containerized deployment. The deployments
  are expected to be alternatives, not active side-by-side in one image.
- [ ] Add the required images to Leda's airgap container workflow so they are
  available from the data partition.
- [ ] Decide whether to extend
  `packagegroup-sdv-airgap-containers` and
  `packagegroup-sdv-additions`, or introduce a separate package group.
- [ ] Document how to select, start, inspect, and troubleshoot the
  containerized deployment.

## Usage guide to complete after implementation

The user-facing Usage section should document the tested Leda workflow and
include:

- how to start the server and check, restart, and stop its systemd service;
- the installed binary and configuration/data locations;
- the HTTP endpoint, port, and a working `curl` example;
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

## Open questions

Still to be confirmed during implementation and image testing:

- Which example vehicle-signal names should be used?
- Do the Vshot default ports match the deployed Kura configuration, and do
  its read/write/subscribe commands work against the running service?
- What are the HTTP API ports and paths?
- Which container runtime and Yoriito images should the later airgap phase
  support, and how should users select one deployment mode?
