#RDEPENDS:${PN} += "kernel-module-dm-thin-pool kernel-module-nf-nat kernel-module-nf-conntrack-netlink kernel-module-xt-addrtype kernel-module-xt-masquerade"
#RDEPENDS:${PN} += "thin-provisioning-tools kernel-module-nf-nat kernel-module-nf-conntrack-netlink kernel-module-xt-addrtype"
#thin-provisioning-tools
RDEPENDS:${PN}:remove = "kernel-module-dm-thin-pool kernel-module-xt-masquerade"
#RDEPENDS:${PN} += "thin-provisioning-tools"