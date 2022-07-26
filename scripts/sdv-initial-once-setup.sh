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
# This script set ups the repository from scratch, it is only
# supposed to be a reference for what has been done before committing the repository,
# in case someone needs to start from scratch.
#
# Add poky as a submodule
POKY_SRC="https://git.yoctoproject.org/poky"
POKY_LOCAL="poky"
[ -d $POKY_LOCAL ] || git submodule add ${POKY_SRC} ${POKY_LOCAL}

YOCTO_RELEASE = "honister"

git submodule add -b ${YOCTO_RELEASE} https://git.yoctoproject.org/meta-raspberrypi meta-raspberrypi
git submodule add -b ${YOCTO_RELEASE} https://git.yoctoproject.org/meta-virtualization meta-virtualization
git submodule add -b ${YOCTO_RELEASE} https://git.openembedded.org/meta-openembedded meta-openembedded
git submodule add -b ${YOCTO_RELEASE} https://git.openembedded.org/meta-openembedded meta-openembedded
git submodule add -b ${YOCTO_RELEASE} https://github.com/rauc/meta-rauc.git meta-rauc
git submodule add -b ${YOCTO_RELEASE} https://git.yoctoproject.org/meta-security meta-security

git submodule add -b main https://github.com/eclipse-leda/meta-leda meta-leda
git submodule add -b main https://github.com/eclipse-leda/leda-utils leda-utils

# git submodule add https://github.com/mem/oe-meta-go oe-meta-go 
# git submodule add -b master https://github.com/meta-rust/meta-rust.git

# ARM64 - Raspi
pushd poky
source oe-init-build-env ../build-sdv-aarch64-rpi4
popd

# ARM32 - Qemu
pushd poky
source oe-init-build-env ../build-sdv-aarch64-qemu
popd

# ARM64 - Qemu
pushd poky
source oe-init-build-env ../build-sdv-arm-qemu
popd

# ARM64 - Qemu
pushd poky
source oe-init-build-env ../build-sdv-x86_64
popd

