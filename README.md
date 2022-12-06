<img src="https://eclipse-leda.github.io/leda/assets/eclipse-leda.png" height="150">

[![BitBake DryRun](https://github.com/eclipse-leda/leda-distro/actions/workflows/dryrun.yml/badge.svg)](https://github.com/eclipse-leda/leda-distro/actions/workflows/dryrun.yml)
[![BitBake Build](https://github.com/eclipse-leda/leda-distro/actions/workflows/build.yml/badge.svg)](https://github.com/eclipse-leda/leda-distro/actions/workflows/build.yml)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

# Eclipse Leda

The Eclipse Leda project provides system image "recipes" to deliver a functional and always-available Linux-based image/distribution in the context of SDV (Software Defined Vehicle), by pulling together individual contributor pieces from [Eclipse SDV](https://sdv.eclipse.org/) and the larger OSS community.

The quickstart images help to learn how the SDV development, test and deployment lifecycle works from an E2E perspective, including the deployment of applications into the container runtimes on constrained embedded devices.

The ready images are also useful for quickly setting up showcases with virtual or real hardware devices.

Eclipse Leda provides a Poky-based reference build pipeline and an OpenEmbedded Metalayer [meta-leda](https://github.com/eclipse-leda/meta-leda) for integration into existing Yocto-based projects.

# Usage

1. Download [latest Eclipse Leda release](https://eclipse-leda.github.io/leda/docs/general-usage/download-releases/)
   or [build from sources](https://eclipse-leda.github.io/leda/docs/build/)
2. Run Eclipse Leda
   - on [emulated QEMU devices](https://eclipse-leda.github.io/leda/docs/general-usage/running-qemu/) or
   - on [Raspberry Pi 4](https://eclipse-leda.github.io/leda/docs/general-usage/raspberry-pi/)
3. Configure device, e.g. [provision the device](https://eclipse-leda.github.io/leda/docs/device-provisioning/)
4. Explore the [device tools](https://eclipse-leda.github.io/leda/docs/build/misc/tools/)
5. Develop your first Vehicle App using [Eclipse Velocitas template](https://github.com/eclipse-velocitas/vehicle-app-python-template)
6. [Deploy a Vehicle App to the device](https://eclipse-leda.github.io/leda/docs/app-deployment/)

Supported Machines / Build Configurations
- Emulated QEMU: x86-64, ARM64
- Raspberry Pi 4

# Documentation

Please see [Eclipse Leda Documentation](https://eclipse-leda.github.io/leda/)

## Features

- Base operating system: Poky from the Yocto project
- Container Runtime: containerd.io
- Control Plane: Kanto Container Management
- Logging and Telemetry: CNCF's OpenTelemetry
- Vehicle Application templates by Eclipse Velocitas
- Vehicle Apps and Vehicle Services programming model by Eclipse Velocitas
- Vehicle Data Broker by Eclipse Kuksa.VAL
- Cloud Connectivity by Eclipse Kanto
- Local Messaging by Mosquitto
- Vehicle Signal Specification by Covesa

## Roadmap

- Integration of additional Eclipse Automotive, Eclipse SDV and Eclipse IoT components, e.g.
  - Eclipse Backend Function Bindings (Specification for automotive cloud services)
  - Eclipse SommR (Some/IP)

# Contributing

Running BitBake to build your own images requires some extra setup on the build machine. Please see [Building Eclipse Leda quickstart images](https://eclipse-leda.github.io/leda/docs/build/) for more information about the build process itself and how to setup a development and build infrastructure.

If you want to contribute bug reports or feature requests, please use *GitHub Issues*.
For reporting security vulnerabilities, please follow our [security guideline](https://eclipse-leda.github.io/leda/docs/project-info/security/).

# License and Copyright

This program and the accompanying materials are made available under the
terms of the Apache License 2.0 which is available at
https://www.apache.org/licenses/LICENSE-2.0

For details, please see our license [NOTICE](NOTICE.md)

