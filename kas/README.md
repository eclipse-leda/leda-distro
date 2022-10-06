# Building

To start a full build, e.g. for the Kirkstone release, run the following command:

    kas build kas/leda-kirkstone.yaml

    kas build -c cleanall kas/leda-kirkstone.yaml k3s

kas will then check out all necessary dependencies as specified in the project configuration file. After that, it will start the build for the machine, distro and target device.

# Running

Running with user-level networking, in case the host does not have TAP/TUN set up properly. If you have TAP/TUN set up, remove the `slirp` keyword. Also enable the OVMF bios for multiboot. If you have kvm enabled on your host, add the `kvm` keyword:

    kas shell kas/leda-kirkstone.yaml -c 'runqemu nographic ovmf kvm'

Boot directly into a specific partition:

    kas shell kas/leda-kirkstone.yaml -c 'runqemu slirp nographic ovmf sdv-image-all'
    kas shell kas/leda-kirkstone.yaml -c 'runqemu slirp nographic ovmf sdv-image-full'
    kas shell kas/leda-kirkstone.yaml -c 'runqemu slirp nographic ovmf sdv-image-minimal'
    kas shell kas/leda-kirkstone.yaml -c 'runqemu slirp nographic ovmf sdv-image-rescue'

# Debugging BitBake

The following commands show the layer setup and information about which recipes are being appended:

    kas shell kas/leda-kirkstone.yaml -c 'bitbake-layers show-layers'
    kas shell kas/leda-kirkstone.yaml -c 'bitbake-layers show-overlayed'
    kas shell kas/leda-kirkstone.yaml -c 'bitbake-layers show-recipes'
    kas shell kas/leda-kirkstone.yaml -c 'bitbake-layers show-appends'
    kas shell kas/leda-kirkstone.yaml -c 'bitbake -c cleanall '
    