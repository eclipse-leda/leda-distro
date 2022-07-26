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

# Clone or update poky repository
git submodule update --init --recursive

pushd poky
# Yocto LTS - Dunfell 3.1
git switch honister

source oe-init-build-env ../build-sdv-aarch64-rpi4

export BB_ENV_EXTRAWHITE="$BB_ENV_EXTRAWHITE REMOTE_CONTAINERS_IPC HTTP_PROXY HTTPS_PROXY http_proxy ftp_proxy https_proxy all_proxy ALL_PROXY no_proxy XDG_RUNTIME_DIR"

#bitbake-layers add-layer ../meta-raspberrypi

rm -rf tmp
time bitbake -c cleanall sdv-image-all

time bitbake sdv-image-all

RC=$?
popd

#
# Record generated files for debugging purposes
#
find build-sdv-aarch64-rpi4/tmp/deploy/images > build-files-report_aarch64-rpi4.txt

exit $RC
