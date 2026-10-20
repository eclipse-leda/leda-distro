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

- [ ] Create the `leda-integration` branch in the Leda fork, based on upstream
  `main`, for Wrynose compatibility work.
- [ ] Port the `meta-yoriito` layer from Scarthgap to Wrynose, keeping changes
  isolated and suitable for contribution upstream where practical.
- [ ] Pin the branch revision and add the layer to the appropriate KAS
  configuration.
- [ ] Build the layer and resolve compatibility issues before adding it to an
  image.

### 2. Install and run natively

- [ ] Put Leda-specific recipes and append files under
  `meta-leda/meta-leda-components/recipes-sdv/yoriito/`.
- [ ] Add a dedicated `packagegroup-sdv-yoriito` package group in the
  Yoriito-specific recipe area for the server, CLI, configuration, and example
  data. Keep Yoriito out of the generic `packagegroup-sdv-additions`.
- [ ] Include the package group in `sdv-image-full` only; do not add it to the
  minimal or rescue images.
- [ ] Add a systemd unit for the server/daemon and enable it by default.
- [ ] Ensure the example configuration and VSS/VSPEC data work with the
  installed server.
- [ ] Keep the CLI tools available on the native image so users can run them
  directly.

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

## Open questions

These technical details need to be confirmed during implementation:

- What are the package names and recipes provided by the upstream layer?
- What systemd unit name and service behavior does Yoriito provide, or must
  Leda add?
- Which example VSS/VSPEC dataset and vehicle-signal names should be used?
- What are the HTTP API and CLI ports, paths, and exact command syntax?
- Which container runtime and Yoriito images should the later airgap phase
  support, and how should users select one deployment mode?
