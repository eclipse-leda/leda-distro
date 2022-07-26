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

DIR="$(pwd)/scripts"
export PATH=$DIR:$PATH

# Some emojis for fun
UNICORN='\U1F984 '
#UNIOK='\U2714 '
UNIOK='\U2705 '
UNIWARNING='\U274C '

# Verify authentication setup
#git submodule init
#git submodule update --recursive
#git-credential-manager-core configure

printf "${UNIOK} Checking for GitHub authentication...\n"
git -C meta-leda pull -v -q

CONTAINER_REGISTRY=ghcr.io

AUTHFILE=$(readlink -f ${HOME}/auth.json)
SKOPEO_STDOUT=$(skopeo login --get-login ${CONTAINER_REGISTRY} --authfile ${AUTHFILE} 2>&1)
SKOPEO_RC=$?

function askSkopeoLogin() {
    while true
    do
        printf "${UNICORN} Do you wish to authenticate to ${CONTAINER_REGISTRY} and store credentials to ${AUTHFILE}?\n"
        select yn in "Yes" "No"; do
            case $yn in
                Yes )
                    skopeo login ${CONTAINER_REGISTRY} --authfile ${AUTHFILE}
                    return 1
                ;;
                No )
                    return 0
                ;;
            esac
        done
    done
}

if [ ${SKOPEO_RC} -eq 0 ]; then
    printf "${UNIOK} Checking authentication for ${CONTAINER_REGISTRY} (${SKOPEO_RC}): ${SKOPEO_STDOUT}\n"
else
    printf "${UNIWARNING} ERROR: Checking authentication for ${CONTAINER_REGISTRY} (${SKOPEO_RC}): ${SKOPEO_STDOUT}\n"
    askSkopeoLogin
fi