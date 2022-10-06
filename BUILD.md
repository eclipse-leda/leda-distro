# Building Leda

Please see the [Leda Documentation](https://eclipse-leda.github.io/leda/docs/build/) for the build requirements and steps involved.

If you are using the provided DevContainer, you can run a build using the `kas` tooling:

    kas build kas/leda-kirkstone.yaml

By default, it will build images for QEMU x86-64.

To build for another target machine, set the `KAS_MACHINE` environment variable:

    KAS_MACHINE=raspberrypi4-64 kas build kas/leda-kirkstone.yaml