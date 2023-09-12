# syntax=docker/dockerfile:1
#
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

FROM debian:bullseye

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

LABEL name="leda-quickstart-x86"

RUN apt-get update
RUN apt-get install -y --no-install-recommends \
    bind9-utils \
    ca-certificates \
    curl \
    dnsmasq \
    dnsutils \
    iproute2 \
    iptables \
    iputils-ping \
    isc-dhcp-server \
    net-tools \
    ssh \
    sudo \
    uml-utilities \
    xz-utils \
    wget

# Debian Bullseye contains QEMU 5.2
# RUN apt-get install -y --no-install-recommends qemu-system-x86

# Debian Bullseye-Backports contains QEMU 7.2
RUN echo "deb http://deb.debian.org/debian bullseye-backports main" > /etc/apt/sources.list.d/debian-bullseye-backports.list
RUN apt-get update
RUN apt-get install -y -t bullseye-backports qemu-system-x86

WORKDIR /root

# Images types:
# auto-osbuild-qemu-autosd9-minimal-ostree -> missing podman
# auto-osbuild-qemu-cs9-qa-ostree -> not AutoSD?
RUN wget --recursive --no-directories --accept-regex "/.*\/auto-osbuild-qemu-cs9-qa-ostree-x86_64-.*\.qcow2.xz$|.*index.html" "https://autosd.sig.centos.org/AutoSD-9/latest/sample-images/"
RUN xz -d *.qcow2.xz
RUN mv *.qcow2 auto-osbuild-qemu-autosd9-minimal-ostree-x86_64.qcow2

RUN apt-get install -y git
RUN git clone https://gitlab.com/CentOS/automotive/sample-images.git

# Expose SSH access
EXPOSE 2222

# Expose MQTT broker: Eclipse Mosquitto
EXPOSE 1883

# Expose Eclipse Kuksa Databroker
EXPOSE 30555

# https://gitlab.com/CentOS/automotive/sample-images/-/blob/main/osbuild-manifests/runvm
ENTRYPOINT [ "/root/sample-images/osbuild-manifests/runvm", \
    "--nographics", \
    "auto-osbuild-qemu-autosd9-minimal-ostree-x86_64.qcow2" \
     ]
