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
#
# Custom BitBake build container for Eclipse Leda:
# - preinstalled: BitBake and its dependencies
# - preinstalled: siemens/kas
#
# Intended to be used by GitHub Runners as custom container images.
#

# Use an environment similar to the devcontainer
FROM debian:bookworm

# Setup non-root user
RUN groupadd -g 1001 bbuser && \
    useradd -r -u 1001 -g bbuser bbuser
RUN mkdir /home/bbuser
RUN chown -R bbuser /home/bbuser
WORKDIR /home/bbuser

# Install Dependencies
RUN apt-get update
RUN apt-get -y install --no-install-recommends socat file gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
        iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \ 
        mesa-common-dev zstd liblz4-tool tmux mc skopeo fdisk ruby-full jq \
        libvirt-clients libvirt-daemon-system qemu-system-x86 qemu-system-arm qemu-kvm \
        squashfs-tools rauc python3-newt

RUN apt-get -y install ca-certificates \
    curl \
    gnupg \
    lsb-release

# Set locale for bitbake inside container
RUN apt-get install -y locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Install kas tool to set up Yocto build environment
RUN pip3 install kas

USER bbuser