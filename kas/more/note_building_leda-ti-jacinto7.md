# Demo

This kas file is provided only as an example for the TI-Jacinto platform. It only has been
verified to build successfully (given that you follow the instructions in this note)
without testing on actual hardware.

# Arago

We only use the base recipes from meta-ti in `leda-ti-jacinto7.yaml`, without depending on
meta-arago which brings in unecessary changes for this demo kas-file.

# Note on building on kernel version choise.

On kirkstone there are two version of the Linux kernel provided - 6.1 and 5.10. 
Kernel 6.1 seems to have problematic recipes, that's why in the
kas-config the recipes `linux-ti-staging_6.1*.bb` are masked-out. This ensures 
that BitBake will only pick up version 5.10 which seems stable/working.

# Important!: Conntrack-netlink kernel module

Kanto Container-Management requires the `kernel-module-nf-conntrack-netlink` 
kernel module to be available as a runtime-dependency. This module is not however
enable in the `linux-ti-staging*` kernel provided by meta-ti by default.

In order to enable it (necessary for a successful build), in a custom meta-layer:

1) Create the following append file `recipes-kernel/linux/linux-ti-staging_%.bbappend` containing:

    ```shell
    FILESEXTRAPATHS:prepend := "${THISDIR}/linux-ti-staging:"
    SRC_URI:append = " file://netlink.cfg"


    KERNEL_CONFIG_FRAGMENTS += " ${WORKDIR}/netlink.cfg"
    ```

2) Create the following config file `recipes-kernel/linux/linux-ti-staging/netlink.cfg` containing the single line:

    ```shell
    CONFIG_NF_CT_NETLINK=y
    ```

__Note__: If you are creating these files under a custom meta-layer you will have to add it to the `leda-ti-jacinto7.yaml` kas file
via the layer path for example:

```yaml
    ...
    meta-my-custom-layer:
        path: <fs_path_to_layer_directory>
        layers:
            meta-my-custom-layer:
```

# Kikstart File

This uses the default kickstart `wks.in` file from d-s-e's fork of meta-rauc-community. While this is sufficient for the
purposes of the build you **should** define a `wks.in` similat to the RPI4-64B one in `meta-leda/meta-leda-distro/wic/raspberrypi.wks.in`.
