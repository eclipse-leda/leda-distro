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

RDEPENDS:${PN}:jetson-nano-2gb-devkit:remove = "kernel-module-dm-thin-pool"
RDEPENDS:${PN}:jetson-nano-2gb-devkit:remove = "kernel-module-xt-masquerade"
RDEPENDS:${PN}:jetson-nano-2gb-devkit:append = " thin-provisioning-tools"

RDEPENDS:${PN}:jetson-nano-devkit:remove = "kernel-module-dm-thin-pool"
RDEPENDS:${PN}:jetson-nano-devkit:remove = "kernel-module-xt-masquerade"
RDEPENDS:${PN}:jetson-nano-devkit:append = " thin-provisioning-tools"