#!/bin/sh
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
# Install SDV Components on Apertis
#
#set -e

# Wait for Apertis to boot and SSH to come up

mkdir -p ~/.ssh/
until ssh-keyscan -t ecdsa -p 2222 -H localhost >> ~/.ssh/known_hosts 2> /dev/null
do
  echo "Bootstrapper: Apertis not up yet (SSH), trying again..."
  sleep 1
done

echo "Bootstrapper: SSH Keyscan successfull"

echo "Bootstrapper: Generating SSH Keys"
ssh-keygen -t rsa -b 2048 -N '' -f /root/.ssh/id_rsa

echo "Bootstrapper: Installing SSH Keys"
sshpass -p user ssh-copy-id -i /root/.ssh/id_rsa.pub -o StrictHostKeyChecking=no -p 2222 user@localhost

echo "Bootstrapper: Checking remote Apertis version"
ssh -o StrictHostKeyChecking=no -o ConnectionAttempts=30 -p 2222 user@localhost "cat /etc/os-release"

echo "Bootstrapper: Executing SDV Installer script (sudo)"
ssh -o StrictHostKeyChecking=no -o ConnectionAttempts=30 -p 2222 user@localhost "sudo -n -s \$SHELL" <  /docker/leda-apertis-install-sdv.sh

echo "Bootstrapper: Done, exiting."
