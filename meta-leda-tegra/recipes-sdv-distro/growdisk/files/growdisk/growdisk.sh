#!/bin/sh
# /********************************************************************************
# * Copyright (c) 2023 Contributors to the Eclipse Foundation
# *
# * See the NOTICE file(s) distributed with this work for additional
# * information regarding copyright ownership.
# *
# * This program and the accompanying materials are made available under the
# * terms of the Eclipse Public License 2.0 which is available at
# * http://www.eclipse.org/legal/epl-2.0
# *
# * SPDX-License-Identifier: EPL-2.0
# ********************************************************************************/
#
echo "Enlarging SD Card partition"

DEVICE=$(lsblk -l | grep part | tail -1 | awk '{print $1}' | sed 's/..$//')
# Last partition on our image is supposed to be "6"
LAST_PARTITION_NUMBER=$(lsblk -l | grep part | wc -l)
PARTITION="/dev/${DEVICE}p${LAST_PARTITION_NUMBER}"

sgdisk /dev/$DEVICE --move-second-header

e2fsck -f -y $PARTITION
echo ',+' | sfdisk /dev/$DEVICE -N $LAST_PARTITION_NUMBER --force
e2fsck -f -y $PARTITION
resize2fs $PARTITION
e2fsck -f -y $PARTITION
sfdisk -Vl /dev/$DEVICE
