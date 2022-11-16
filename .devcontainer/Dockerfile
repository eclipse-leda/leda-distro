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

# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.245.2/containers/debian/.devcontainer/base.Dockerfile

# [Choice] Debian version (use bullseye on local arm64/Apple Silicon): bullseye, buster
ARG VARIANT="bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/base:0-${VARIANT}

# ** [Optional] Uncomment this section to install additional packages. **
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# Install Dependencies
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends socat file gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
        iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \ 
        mesa-common-dev zstd liblz4-tool tmux mc skopeo fdisk ruby-full jq \
        libvirt-clients libvirt-daemon-system qemu-system-x86 qemu-system-arm qemu-kvm \
        squashfs-tools rauc python3-newt

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install ca-certificates \
    curl \
    gnupg \
    lsb-release

# Install latest docker
RUN sudo mkdir -p /etc/apt/keyrings
RUN sudo rm -f /etc/apt/keyrings/docker.gpg
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN sudo apt-get update
RUN sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install blobfuse2 since blobfuse1 is not avaialable in MS repos for Debian 11
RUN sudo apt-get -y install software-properties-common \
    && curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - \
    && sudo apt-add-repository https://packages.microsoft.com/debian/11/prod/ \
    && sudo apt-get -y update \
    && sudo apt-get -y install libfuse3-dev fuse3 blobfuse2

# Try to enable KVM to improve performance of qemu-system-x86 on x86 hosts.
# This is also run in post-attach.sh
RUN /bin/bash -c "(groupadd --system kvm; gpasswd -a vscode kvm; chown root:kvm /dev/kvm; chmod 0660 /dev/kvm; echo 'KVM permissions set up') || true"

# Install kas tool to set up Yocto build environment
RUN pip3 install kas
