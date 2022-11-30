#!/bin/bash
# /********************************************************************************
# * Copyright (c) 2022 Contributors to the Eclipse Foundation
# *
# * See the NOTICE file(s) distributed with this work for additional
# * information regarding copyright ownership.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Apache License 2.0 which is available at
# * https://www.apache.org/licenses/LICENSE-2.0
# *
# * SPDX-License-Identifier: Apache-2.0
# ********************************************************************************/
#
# Run qemu with TAP network
#
# set -x 

if [ -z "$1" ];
then
    echo "Usage: sudo $0 [1..5]"
    exit 1;
fi

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi


INSTANCE="$1"

TMPDIR="build/tmp"

# Create overlays of the qcow2 files

# Step 1 - delete existing, so we start from scratch
#rm -f disk-instance-${INSTANCE}.qcow2
#rm -f ovmf-instance-${INSTANCE}.qcow2

# Step 2 - Create new disk overlays
$TMPDIR/work/x86_64-linux/qemu-helper-native/1.0-r1/recipe-sysroot-native/usr/bin/qemu-img create -F qcow2 -f qcow2 -b build/tmp/deploy/images/qemux86-64/sdv-image-all-qemux86-64.wic.qcow2 disk-instance-${INSTANCE}.qcow2
$TMPDIR/work/x86_64-linux/qemu-helper-native/1.0-r1/recipe-sysroot-native/usr/bin/qemu-img create -F qcow2 -f qcow2 -b build/tmp/deploy/images/qemux86-64/ovmf.qcow2 ovmf-instance-${INSTANCE}.qcow2

$TMPDIR/work/x86_64-linux/qemu-helper-native/1.0-r1/recipe-sysroot-native/usr/bin/qemu-system-x86_64 \
-device virtio-net-pci,netdev=net0,mac=52:54:00:12:34:0${INSTANCE} \
-netdev tap,id=net0,ifname=tap${INSTANCE},script=no,downscript=no \
-object rng-random,filename=/dev/urandom,id=rng0 \
-device virtio-rng-pci,rng=rng0 \
-drive id=hd,file=disk-instance-${INSTANCE}.qcow2,if=virtio,format=qcow2 \
-enable-kvm \
-serial mon:stdio \
-serial null \
-serial mon:vc \
-nographic \
-object can-bus,id=canbus0 \
-device kvaser_pci,canbus=canbus0 \
-drive if=pflash,format=qcow2,file=ovmf-instance-${INSTANCE}.qcow2 \
-cpu IvyBridge \
-machine q35 \
-smp 4 \
-m 4G
