# Eclipse Leda Maintainer Guidance

Eclipse Leda is a Poky-based, experimental SDV playground distributed as ready-to-use images for hackathons, learning, and demonstrations. This repository defines the distro build; `meta-leda` is maintained separately and can also be integrated by other Yocto projects.

## Build and configuration

- Use kas as the entry point for preparing and building images. The supported machine configurations are `kas/leda-qemux86-64.yaml`, `kas/leda-qemuarm64.yaml`, and `kas/leda-raspberrypi4-64.yaml`; shared settings and pinned layer revisions are in `kas/common-wrynose.yaml`.
- Make dependency and layer revision changes in kas configuration, not in a local checkout. Keep pins reproducible. Treat the latest Yocto LTS as the baseline; maintain compatibility with other supported releases and track the current development release where practical.
- This is a BitBake-built image, not a general-purpose apt-based system. Add or change target software through the appropriate Yocto layer, recipe, or image configuration.
- Preserve compatibility for existing users where practical. Clearly flag changes that may affect image behavior, deployment, or clients for review.

## Maintenance

- Prefer actively maintained upstream software and relevant Eclipse SDV, Eclipse IoT, AGL, COVESA, SOAFEE, and ELISA projects when they fit the use case. Prefer LTS bases while tracking the Yocto development release for early compatibility feedback.
- Before carrying or adding a patch to an external recipe, check upstream issue trackers and existing fixes; prefer an existing layer or upstream fix over copying code or maintaining a local patch. Revisit workarounds when updating their upstream component.
- Image-level convenience defaults may favor hackathon usability over production hardening. Keep that tradeoff scoped to the non-production image; it does not waive security hygiene for build infrastructure, dependencies, secrets, or newly introduced functionality.
- Keep images suitable for quick experimentation while considering their size. Raise unusually large additions for maintainer review before accepting the cost or removing existing functionality.
- Keep `README.md` and `BUILD.md` as concise entry points. Put detailed rationale and contributor documentation in `docs/` or the project documentation site.
- Changes under `scripts/`, `resources/`, and `examples/` support building, running, or trying Leda; preserve their intended contributor and user workflows.

## Validation

- Use the affected kas configuration to validate build or configuration changes when feasible, and run the related checks or CI for scripts and resources. State clearly what was and was not validated.
- Follow the build requirements and detailed steps in the [Leda build documentation](https://eclipse-leda.github.io/leda/docs/build/).
