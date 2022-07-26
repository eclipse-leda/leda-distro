do_install:append() {
   sed -i -e 's,root=/dev/mmcblk0p2 rootfstype=ext4,root=/dev/mmcblk0p2 rootfstype=ext4 cgroup_memory=1 cgroup_enable=memory,g' ${WORKDIR}/cmdline.txt
}
