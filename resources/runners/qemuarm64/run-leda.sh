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

qemu-system-aarch64 \
        -kernel ./Image-qemuarm64.bin \
        -m 2G \
        -machine virt \
        -cpu cortex-a57 \
        -nographic \
        -drive if=none,file=sdv-image-all-qemuarm64.wic.qcow2,format=qcow2,id=hd \
        -device virtio-blk-device,drive=hd \
        -net nic,model=virtio \
        -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1880-:1880,hostfwd=tcp::1883-:1883,hostfwd=tcp::8888-:8888,hostfwd=tcp::30555-:30555 \
        -object can-bus,id=canbus0 \
        -device kvaser_pci,canbus=canbus0 \
        -bios u-boot.bin
