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

# Optional: Mount Azure Storage as remote sstate-cache to improve build time.
# This is only required if you want to manually upload / sync build artifacts to your remote sstate-cache
# To configure the sstate-cache and upload local build artifacts, the following environment variables need to be set:
# AZURE_MOUNT_POINT="azure-sstate-cache"
# AZURE_STORAGE_ACCESS_KEY="<Access key>"
# AZURE_STORAGE_ACCOUNT="sdvyocto" // Replace with your storage name
# AZURE_STORAGE_ACCOUNT_CONTAINER="yocto-sstate-cache" // Replace with your storage container name
if [ -n "${AZURE_MOUNT_POINT}" ] && [ -n "${AZURE_STORAGE_ACCOUNT_CONTAINER}" ]; then
    [ -d ${AZURE_MOUNT_POINT} ] || mkdir -p ${AZURE_MOUNT_POINT}
    if $(blobfuse2 mount list | grep -q "${AZURE_MOUNT_POINT}"); then
        echo "Unmounting remote sstate-cache: ${AZURE_MOUNT_POINT}"
        blobfuse2 --disable-version-check unmount ${AZURE_MOUNT_POINT}
    fi
    TEMPD=$(mktemp -d)
    echo "Mounting remote sstate-cache on Azure Storage Account ${AZURE_STORAGE_ACCOUNT_CONTAINER} to local path: ${AZURE_MOUNT_POINT}"
    blobfuse2 --disable-version-check mount ${AZURE_MOUNT_POINT} --log-level LOG_DEBUG --use-https=true --tmp-path=$TEMPD --container-name=${AZURE_STORAGE_ACCOUNT_CONTAINER} || true
else
    echo "Warning: No AZURE_MOUNT_POINT or no AZURE_STORAGE_ACCOUNT_CONTAINER set for remote sstate-cache."
fi
