#!/bin/bash
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
#
# Bash strict mode
set -euo pipefail
apt-get update
apt-get -y install --no-install-recommends wget
apt-get -y install --no-install-recommends containerd
command -v containerd

wget "https://github.com/eclipse-kanto/kanto/releases/download/v0.1.0-M3/kanto_0.1.0-M3_linux_x86_64.deb"
apt-get install -y ./kanto_0.1.0-M3_linux_x86_64.deb
command -v container-management
command -v kanto-cm

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-utils_0.0.2.0.00680_all.deb"
apt-get install -y ./eclipse-leda-utils_0.0.2.0.00680_all.deb

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-kantui_0.0.2.0.00680_amd64.deb"
apt-get install -y ./eclipse-leda-kantui_0.0.2.0.00680_amd64.deb

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-kanto-auto-deployer_0.0.2.0.00680_amd64.deb"
apt-get install -y ./eclipse-leda-kanto-auto-deployer_0.0.2.0.00680_amd64.deb

wget "https://github.com/eclipse-leda/meta-leda/releases/download/0.1.0-M2/eclipse-leda-containers_0.1.0.2.0.422_all.deb"
apt-get install -y ./eclipse-leda-containers_0.1.0.2.0.422_all.deb
