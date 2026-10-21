# Plan: generalize SDV service deployment types

## Status and motivation

This is a proposed design, not an implemented configuration interface.
The current Kura integration uses `LEDA_YORIITO_DEPLOYMENT` to choose between
native systemd activation and a Kanto-managed container. Its recipe wiring is
documented in [Container build workflows](containers.md#maintain-a-service-with-native-and-container-deployment-modes).

Extend that approach to services such as Databroker, HVAC, and seat service
without requiring users to learn a separate switch and package/manifest
combination for every service. Centralize repeated selection logic while
keeping application-specific runtime configuration explicit.

## Goals

- Let users select deployment modes with a small, consistent interface in
  distro configuration, downstream configuration, or KAS overlays.
- Separate service activation from installation of native clients and tools.
- Reuse existing application recipes, OCI/cache recipes, and Kanto descriptors.
- Preserve current defaults for services that users do not override.
- Validate configuration early instead of silently ignoring mistakes.
- Keep the mechanism usable by downstream `meta-leda` consumers without KAS.
- Reduce duplicated conditionals and documentation across service integrations.

## Proposed user interface

```bitbake
LEDA_DEPLOYMENT_CONTAINER:append = " yoriito databroker"
LEDA_DEPLOYMENT_NATIVE:append = " hvac-service seat-service"

LEDA_NATIVE_PACKAGES:append = " vshot databroker-cli"
```

These are whitespace-separated BitBake lists, not arrays or comma-separated
values. `:append` does not insert a separator automatically, so include the
leading space.

| Variable | Proposed meaning |
| --- | --- |
| `LEDA_DEPLOYMENT_CONTAINER` | Explicitly select container deployment for the listed service identifiers. |
| `LEDA_DEPLOYMENT_NATIVE` | Explicitly select native deployment for the listed service identifiers. |
| `LEDA_NATIVE_PACKAGES` | Add native packages to the applicable host image independently of service deployment mode. |

Service identifiers are stable public names, not necessarily recipe or package
names. For example, `yoriito` selects the Kura service integration; it is not a
request to install a package literally named `yoriito`. Document the available
identifiers and supported modes in one registry.

Native package entries, by contrast, name actual installable packages.
Containerized Databroker can therefore coexist with a native `databroker-cli`,
and containerized Kura with native `vshot`.

`LEDA_NATIVE_PACKAGES` is a host-image convenience interface, not a replacement
for all Yocto package selection. It must not add packages to OCI runtime images,
the data image, or minimal/rescue images implicitly. Document the host image
scope explicitly; start with the full image.

### Defaults and override semantics

Keep explicit selections separate from per-service defaults:

1. Read the service registry and validate the requested identifiers.
2. Reject any service explicitly selected in both deployment lists.
3. Use an explicit selection when present.
4. Otherwise use the service's existing default and image eligibility.

Do not populate the explicit lists with distro defaults: a user appending a
service to the other list would then create an artificial conflict. Defaults
belong in service metadata and explicit choices override them.

An unmentioned service must not become newly installed merely because it has
a registry entry. Preserve its existing inclusion policy. An explicit selection
should include that service in the applicable image even if it was not part
of the default selection.

For an already selected service, omission from both lists means “use its
default,” not “disable it.” A disabled deployment mode is outside the initial
scope; do not imply that removing an explicit override removes the service.

## Proposed maintainer model

Introduce shared deployment metadata and helpers in `meta-leda`. A small
service registry should describe the following information for each service:

| Metadata | Purpose |
| --- | --- |
| Stable identifier | User-facing name and documentation lookup. |
| Supported modes | Reject selections for which recipes/runtime integration do not exist. |
| Default mode and inclusion policy | Preserve existing distro/image behavior. |
| Native server packages | Packages required for native deployment. |
| Native systemd units and owning packages | Control activation, including split service packages. |
| Shared client/data packages | Retain required native tools or data in either mode. |
| Container archive packages | Include locally built or prebuilt images for offline import. |
| Kanto deployment packages | Install the matching active descriptors on the data partition. |

The exact metadata variable names and representation remain implementation
decisions. Prefer existing BitBake conventions and a small include/class over
a new configuration language or a generic framework with many extension points.

### Shared responsibilities

The shared implementation should:

- Resolve explicit selections and defaults consistently across host and data
  images, package groups, and application recipes.
- Select native server packages when required and shared clients/data in the
  applicable host image.
- Enable the intended native units only for native deployment.
- Include matching archive and deployment packages together for container mode.
- Include `airgap-container-installer` on the host whenever selected containers
  depend on local archives, independently of the generic `airgap-containers`
  feature.
- Exclude the alternative service's default manifest/activation path so a
  service is not deployed twice through old package groups.
- Report invalid or unsupported selections with actionable BitBake errors.

Installing a native executable must not by itself enable a competing native
service. Kura currently retains its native server binary in container mode;
do not require its removal merely to adopt the generalized interface.

Service activation policy must also remain correct inside OCI image builds:
those images reuse application packages but do not boot the host's systemd
service. Avoid recursive inclusion of host deployment packages in OCI images.

### Responsibilities that stay service-specific

Keep these explicit in existing recipes and descriptors:

- Application sources, dependencies, patches, licensing, and package splitting.
- OCI contents, entrypoint, arguments, environment, and image reference.
- Choice of locally built OCI image or externally published image cache.
- Networking, ports, privileges, mounts, and restart behavior.
- Configuration/data packaging and application-specific API validation.

Do not attempt to generate every Kanto descriptor from a service name.
For example, Kura's loopback listeners require host networking, while other
services may need different isolation or connectivity.

Archive references must match descriptor references exactly. Retain
content-dependent archive filenames for locally built images because the
current importer remembers successful imports by filename. These guarantees
must survive moving selection logic into shared helpers.

## Validation rules

Fail explicitly for:

- Unknown service identifiers.
- A service listed in both explicit mode lists.
- A mode unsupported by the selected service.
- Incomplete required registry metadata, such as a container mode without its
  archive or descriptor package mapping.

Duplicate entries within one list can be normalized; they are not conflicting
mode selections. Use normal BitBake package dependency resolution for missing
package providers rather than silently dropping requested native packages.

Image references and actual runtime behavior still require build/runtime
checks; metadata validation alone cannot establish that a service works.

## Migration plan

1. Inventory current service packages, units, manifests, cached images, and
   inclusion defaults. In particular, identify manifests selected through
   `sdv-core-containers` and `sdv-example-containers` to avoid duplicate
   deployment paths.
2. Define the minimal registry and shared resolution logic. Add focused tests
   for list parsing, defaults, explicit overrides, conflicts, and image scope.
3. Migrate Yoriito first, retaining its current native default and offline
   container behavior. Replace repeated conditionals with the shared result.
4. Migrate Databroker next. It exercises an existing default container
   deployment, prebuilt image caching, and independently installed native CLI.
   Only advertise native mode once its units and configuration are validated.
5. Migrate HVAC and seat service when their native and container implementations
   are available and verified. Report unsupported modes rather than inventing
   placeholder support.
6. Update KAS examples, maintainer guidance, and runtime documentation to use
   the common interface.

For the existing `LEDA_YORIITO_DEPLOYMENT` interface, prefer a transitional
compatibility mapping with a deprecation warning rather than an immediate
silent behavior change. Translate an explicitly supplied legacy value only
when no new explicit Yoriito selection exists; report contradictory choices.
Move the old implicit native default into service metadata so it cannot be
mistaken for an explicit user override.

## Acceptance tests

- Unmodified configuration preserves current service selections and image scope.
- Each supported service can be explicitly selected in either supported mode.
- Native mode enables the correct units and excludes that service's active
  Kanto descriptor and unneeded archive from a fresh data image.
- Container mode prevents native auto-start, imports the correct image, and
  auto-deploys exactly one Kanto container.
- Client tools remain available regardless of their server's deployment mode.
- Container selection works with generic `airgap-containers` enabled or removed.
- Conflicts, unknown identifiers, unsupported modes, and invalid legacy values
  produce clear errors.
- OCI images do not inherit host-only tools or deployment dependencies.
- Minimal/rescue images do not gain services or native tools unintentionally.
- Effective BitBake metadata, package manifests, boot behavior, and actual
  client/API operations agree with the requested deployment.
- Check disk usage and architecture support, starting with QEMU x86-64 and
  extending to QEMU ARM64 and Raspberry Pi.

Build final bootable images, not just the component packages. Test fresh data
partitions when changing modes.

## Non-goals and later work

- Runtime mode switching or automatic migration of persistent Kanto state.
- Automatically generating application recipes, OCI entrypoints, or descriptors.
- Removing every unused native binary as part of the initial migration.
- Adding a third “disabled” mode before its inclusion semantics are designed.

Changing only a RAUC rootfs slot leaves the data partition's manifests, images,
and container state intact. The initial interface is a build-time policy;
document the fresh-disk requirement rather than suggesting that a new build
selection reconciles an existing installation. A later reconciliation design
must define how to stop/remove old deployments and preserve application data.
