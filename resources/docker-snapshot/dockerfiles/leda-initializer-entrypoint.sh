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
mkdir -p ~/.ssh/

while ! ssh -o StrictHostKeyChecking=no -o BatchMode=yes -p 2222 leda-x86 exit
do
    echo "Trying again..."
done
ssh-keyscan -p 2222 -H leda-x86 >> ~/.ssh/known_hosts 2> /dev/null
ssh -o BatchMode=yes -p 2222 root@leda-x86 "kanto-cm create --name cadvisor --ports=8888:8080 --mp='/run/containerd/containerd.sock:/run/containerd/containerd.sock' --mp='/:/rootfs' --mp='/var/run:/var/run' --mp='/sys:/sys' --mp='/dev/disk:/dev/disk' --mp='/proc:/hostproc' --privileged gcr.io/cadvisor/cadvisor:v0.47.1"
ssh -o BatchMode=yes -p 2222 root@leda-x86 "kanto-cm start --name cadvisor"


while ! ssh -o StrictHostKeyChecking=no -o BatchMode=yes -p 2222 leda-arm64 exit
do
    echo "Trying again..."
done
ssh-keyscan -p 2222 -H leda-arm64 >> ~/.ssh/known_hosts 2> /dev/null
ssh -o BatchMode=yes -p 2222 root@leda-arm64 "kanto-cm create --name cadvisor --ports=8888:8080 --mp='/run/containerd/containerd.sock:/run/containerd/containerd.sock' --mp='/:/rootfs' --mp='/var/run:/var/run' --mp='/sys:/sys' --mp='/dev/disk:/dev/disk' --mp='/proc:/hostproc' --privileged gcr.io/cadvisor/cadvisor:v0.47.1"
ssh -o BatchMode=yes -p 2222 root@leda-arm64 "kanto-cm start --name cadvisor"
