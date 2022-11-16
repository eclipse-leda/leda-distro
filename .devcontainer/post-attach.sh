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

# Enable KVM
# sudo groupadd --system kvm
# sudo gpasswd -a $USER kvm

# Enable KVM Device for access to user (as qemu us run as non-root
sudo chown root:kvm /dev/kvm
sudo chmod 0660 /dev/kvm

# Optional: Mount Azure Storage as remote sstate-cache to improve build time
if [ -n "${AZURE_MOUNT_POINT}" ] && [ -n "${AZURE_STORAGE_ACCOUNT_CONTAINER}" ]; then
    rmdir ${AZURE_MOUNT_POINT} || true
    mkdir -p ${AZURE_MOUNT_POINT} || true
    TEMPD=$(mktemp -d)
    echo "Mounting ${AZURE_STORAGE_ACCOUNT_CONTAINER} to ${AZURE_MOUNT_POINT}"
    blobfuse2 mount ${AZURE_MOUNT_POINT} --log-level LOG_DEBUG --use-https=true --tmp-path=$TEMPD --container-name=${AZURE_STORAGE_ACCOUNT_CONTAINER} || true
else
    echo "Warning: No AZURE_MOUNT_POINT or no AZURE_STORAGE_ACCOUNT_CONTAINER set for remote sstate-cache."
fi
