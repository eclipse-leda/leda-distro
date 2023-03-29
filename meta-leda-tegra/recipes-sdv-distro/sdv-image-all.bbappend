# /********************************************************************************
# * Copyright (c) 2023 Contributors to the Eclipse Foundation
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
COMPATIBLE_MACHINE = "tegra210"
# Tegra needs a plain WIC file (not qcow2) to be flashed to SD-Card
WKS_FILE:jetson-nano-2gb-devkit ?= "jetson-sdcard.wks"
IMAGE_FSTYPES:jetson-nano-2gb-devkit = "tegraflash tar.gz wic.gz"
# Allow wics to partition this image by providing boot files
IMAGE_BOOT_FILES:jetson-nano-2gb-devkit = "Image u-boot.bin tegra210-p3448-0003-p3542-0000-jetson-nano-2gb-devkit.dtb u-boot-jetson-nano-2gb-devkit.bin"
INCOMPATIBLE_LICENSE = ""