# Edge Stack as Debian packages

Eclipse Leda is supposed to be the Eclipse SDV In-Vehicle / Edge stack reference implementation.

The current implementation to build the quickstart images is using Yocto/Poky as a base distribution and build system.
This is due to the fact that most embedded OEM device manufacturers using Yocto as a de-facto standard distribution and build tooling for their SDKs. For an easy integration into the OpenEmbedded ecosystem, the Leda project decided to use Poky and provide an OpenEmbedded Meta-Layer (meta-leda) to be used by system integration teams.

For existing, popular Linux distributions and ecosystems like Ubuntu, Debian, Raspberry Pi OS etc., it would be much easier for users to install Eclipse Leda using built-in package managers, such as `apt`.

This repository is an attempt into building up the Leda edge stack for easy installation on Debian systems.

## Edge Stack Components

The following components are supposed to be installed:

- Mosquitto
- systemd (optional)
- d-bus (optional, for self-update-agent and RAUC integration)
- containerd.io
- -RAUC Update Service- - the self-update use case is not applicable in this case
- Eclipse Kanto Container Management - extends containerd
- Eclipse Kuksa.VAL Data Broker - deployed as container into Kanto
- Eclipse Leda Utils (sdv-health, kantui, kanto-auto-deployer)

## Concept

1. Retrieve Debian packages from GitHub
2. Use a single installation script for multiple base OS distros
3. Reuse packages from host distro (eg containerd on Debian vs. containerd.io on Ubuntu)
4. Testing of installation steps done in Docker

> Note: As our project does not yet have a public Debian repository, users need to download the Debian packages manually.

## Package sources

Some components are already available as .deb packages on GitHub (but not yet in the Debian repository).

- Eclipse Kanto: Container Management is available as .deb packages on GitHub
- Eclipse Leda: leda-utils, kantui and kanto-auto-deployer as .deb packages on GitHub

## Testing installation

To test the installation, we're using a `debian` and `ubuntu` Docker base images.

As we're running a containerd instance inside of a Docker container, the container requires some additional privileges and the `SYS_ADMIN` capability.

```shell
docker run --rm --privileged --cap-add=SYS_ADMIN ghcr.io/eclipse-leda/leda-distro/leda-test-ubuntu23
```
