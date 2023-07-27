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

RUN wget https://autosd.sig.centos.org/AutoSD-9/nightly/sample-images/auto-osbuild-qemu-cs9-qa-ostree-x86_64-946743607.247784c5.qcow2.xz
RUN xz -d auto-osbuild-qemu-cs9-qa-ostree-x86_64-946743607.247784c5.qcow2.xz

RUN apt-get install -y git
RUN git clone https://gitlab.com/CentOS/automotive/sample-images.git

ADD leda-qemu-autosd-entrypoint.sh /leda-qemu-autosd-entrypoint.sh

# TODO: Setup DHCP and DNS server

# Expose SSH access
EXPOSE 2222

# Expose MQTT broker: Eclipse Mosquitto
EXPOSE 1883

# Expose Eclipse Kuksa Databroker
EXPOSE 30555

# ENTRYPOINT [ "/leda-qemu-autosd-entrypoint.sh" ]
# https://gitlab.com/CentOS/automotive/sample-images/-/blob/main/osbuild-manifests/runvm
ENTRYPOINT [ "/root/sample-images/osbuild-manifests/runvm", \
    "--nographics", \
    "auto-osbuild-qemu-cs9-qa-ostree-x86_64-946743607.247784c5.qcow2" \
     ]
