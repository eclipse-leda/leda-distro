![Eclipse Leda](docs/eclipse-leda.png)

# Eclipse Leda


The Eclipse Leda project provides system image "recipes" to deliver a functional and always-available Linux-based image/distribution in the context of SDV (Software Defined Vehicle), by pulling together individual contributor pieces from [Eclipse SDV](https://sdv.eclipse.org/) and the larger OSS community.

The quickstart images help to learn how the SDV development, test and deployment lifecycle works from an E2E perspective, including the deployment of applications into the container runtimes on constrained embedded devices.

The ready images are also useful for quickly setting up showcases with virtual or real hardware devices.

Eclipse Leda provides a Poky-based reference build pipeline and an OpenEmbedded Metalayer [meta-leda](https://github.com/eclipse-leda/meta-leda) for integration into existing Yocto-based projects.

# Usage

1. Download [latest Eclipse Leda release](docs/general-usage/download-releases.md)
2. Run Eclipse Leda
   - on [emulated Qemu devices](docs/qemu/readme.md) or
   - on [Raspberry Pi 4](docs/raspberry-pi/readme.md)
3. Configure device, e.g. [provision the device](docs/device-provisioning/readme.md)
4. Explore the [device tools](docs/misc/tools.md)
5. Develop your first Vehicle App using [Eclipse Velocitas template](https://github.com/eclipse-velocitas/vehicle-app-python-template)
6. [Deploy a Vehicle App to the device](docs/app-deployment/readme.md)

Supported Machines / Build Configurations
- Emulated Qemu: x86-64, ARM64, ARM
- Raspberry Pi 4

# Documentation

Please see [Eclipse Leda Documentation](docs/readme.md)

# Overview

![Eclipse Leda Component Overview](docs/eclipse-leda-arch-overview.png)

## Features

- Base operating system: Poky from the Yocto project
- Container Runtime: containerd.io
- Kubernetes Control Plane: Rancher's k3s.io
- Logging and Telemetr: CNCF's OpenTelemetry
- Vehicle Application templates by Eclipse Velocitas
- Vehicle Apps and Vehicle Services programming model by Eclipse Velocitas
- Cloud Connectivity by Eclipse kanto
- Local Messaging by Mosquitto
- Vehicle Signal Specification by Covesa

## Roadmap

- Integration of additional Eclipse Automotive, Eclipse SDV and Eclipse IoT components, e.g.
  - Eclipse Backend Function Bindings
  - Eclipse Kuksa.val

# Contributing

Running BitBake to build your own images requires some extra setup on the build machine. Please see [Building Eclipse Leda quickstart images](docs/build/readme.md]) for more information about the build process itself and how to setup a development and build infrastructure.

If you want to contribute bug reports or feature requests, please use *GitHub Issues*.
For reporting security vulnerabilities, please follow our [security guideline](docs/security/readme.md).

# License and Copyright

This program and the accompanying materials are made available under the
terms of the Apache License 2.0 which is available at
https://www.apache.org/licenses/LICENSE-2.0

For details, please see our license [NOTICE](NOTICE.md)

