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

FROM debian

# Update packages
RUN apt-get update

# Install BitBake and Tinfoilhat Dependencies
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends socat file gawk wget git diffstat unzip texinfo \
        gcc build-essential chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
        iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit \ 
        mesa-common-dev zstd liblz4-tool tmux mc ca-certificates curl python3-yaml rsync rpm unzip xz-utils lzip git locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

ENV LANG en_US.UTF-8 

# Install Tinfoilhat
RUN git clone https://gitlab.eclipse.org/eclipse/oniro-compliancetoolchain/toolchain/tinfoilhat.git
RUN cp tinfoilhat/tinfoilhat.py /usr/bin/tinfoilhat && chmod +x /usr/bin/tinfoilhat
RUN cp tinfoilhat/aliensrc_creator.py /usr/bin/aliensrc_creator && chmod +x /usr/bin/aliensrc_creator

WORKDIR /app
ADD tinfoilhat-entrypoint.sh /app

RUN useradd --create-home --shell /bin/bash bitbake

USER bitbake
WORKDIR /home/bitbake

ENTRYPOINT [ "/app/tinfoilhat-entrypoint.sh" ]
