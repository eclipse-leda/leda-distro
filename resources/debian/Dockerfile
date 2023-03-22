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

FROM debian:bullseye AS build

ARG DEBIAN_FRONTEND=noninteractive
ARG TZ=Etc/UTC

LABEL name="leda-debian-x86"

COPY public.key.gpg /etc/apt/trusted.gpg.d/

RUN apt-get update
RUN apt-get install -y ca-certificates
RUN echo "deb https://sdvyocto.blob.core.windows.net/debian dracon main" > /etc/apt/sources.list.d/sdv.list
RUN apt-get update

RUN apt install -y leda-utils
