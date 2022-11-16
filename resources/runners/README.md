# Leda Runners

The Leda runner scripts are for users to run a released Leda distro image using QEMU.

The scripts perform these additional steps:
- Install dependencies (qemu-system, uml-utilities for tunctl)
- Setting up virtual network (TAP)
- Populating QEMU command line arguments

The functionality is similar to the `runqemu` script from BitBake.

The files get packaged into the Leda release archive.