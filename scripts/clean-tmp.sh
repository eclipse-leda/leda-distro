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
# Clean temporary files to save disk space.
# When you run this script, the build needs to rerun and re-fetch all downloads, recompile everything etc, as the cache will be cleared.
#

#git clean -fxd

rm build-sdv-aarch64-qemu/cache
rm build-sdv-aarch64-qemu/sstate-cache
rm build-sdv-aarch64-qemu/tmp
rm build-sdv-aarch64-qemu/*.log
rm build-sdv-aarch64-qemu/*.sock
rm build-sdv-aarch64-qemu/*.lock

