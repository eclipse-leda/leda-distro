# Building Leda

Please see the [Leda Documentation](https://eclipse-leda.github.io/leda/docs/build/) for the build requirements and steps involved.

## Quick Steps

1. Clone the leda-distro repository:

        git clone https://github.com/eclipse-leda/leda-distro.git

2. Install [kas tool](https://kas.readthedocs.io/en/latest/userguide.html#dependencies-installation). If you are using the provided DevContainer, the build tools are already preinstalled.

3. Start the build for qemux86_64:

        kas build kas/leda-qemux86-64.yaml

4. To build for another target machine, is the other kas config files:

        kas build kas/leda-raspberrypi4-64.yaml
