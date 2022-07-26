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

qemu-system-x86_64 \
 -device virtio-net-pci,netdev=net0,mac=52:54:00:12:35:02 \
 -netdev user,id=net0,hostfwd=tcp::2222-:22 \
 -object rng-random,filename=/dev/urandom,id=rng0 \
 -device virtio-rng-pci,rng=rng0 \
 -drive file=./build-sdv-x86_64/tmp/deploy/images/qemux86-64/sdv-image-all-qemux86-64-20220324170816.rootfs.ext4,if=virtio,format=raw \
 -usb \
 -device usb-tablet \
 -cpu IvyBridge \
 -machine q35 \
 -smp 4 \
 -m 2048 \
 -serial mon:stdio \
 -serial null \
 -nographic \
 -kernel ./build-sdv-x86_64/tmp/deploy/images/qemux86-64/bzImage--5.14.21+git0+f9e349e174_9d5572038e-r0-qemux86-64-20220323081046.bin \
 -append "root=/dev/vda rw mem=2048M ip=dhcp console=ttyS0 console=ttyS1 oprofile.timer=1 tsc=reliable no_timer_check rcupdate.rcu_expedited=1"
