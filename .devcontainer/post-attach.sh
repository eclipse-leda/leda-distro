#!/bin/bash
# /********************************************************************************
# * Copyright (c) 2022-2026 Contributors to the Eclipse Foundation
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

# Enable KVM
# sudo groupadd --system kvm
# sudo gpasswd -a $USER kvm

# Enable KVM Device for access to user (as qemu us run as non-root
sudo chown root:kvm /dev/kvm
sudo chmod 0660 /dev/kvm

# Named volumes for caching sstate and downloads is owned by root initially
sudo chown ${USER} ${PWD}/build
sudo chown ${USER} ${PWD}/build/downloads
sudo chown ${USER} ${PWD}/build/sstate-cache

function take_workspace_ownership() {
    local USER=$1
    local DIR=$2
    sudo chown -R ${USER} ${DIR}
    sudo setfacl -bnR ${DIR}
}

# There is a umask issue in GitHub codespaces
# possibly related to: https://github.com/orgs/community/discussions/26026
# which causes some recipes to fail to build, due to wrong permissions (e.g. gpsd)
if [ -n "$CODESPACE_VSCODE_FOLDER" ]; then 
    take_workspace_ownership $(whoami)  ${CODESPACE_VSCODE_FOLDER}
fi
