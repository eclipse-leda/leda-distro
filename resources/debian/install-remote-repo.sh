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

sudo bash -c "echo \"deb https://sdvyocto.blob.core.windows.net/debian dracon main\" > /etc/apt/sources.list.d/sdv.list"
gpg --output public.key.gpg --export leda-dev@eclipse.org
# gpg --output private.pgp --armor --export-secret-key leda-dev@eclipse.org
# gpg --output public.pgp --armor --export leda-dev@eclipse.org
sudo cp public.key.gpg /etc/apt/trusted.gpg.d/
sudo apt update
apt search leda