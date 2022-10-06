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
