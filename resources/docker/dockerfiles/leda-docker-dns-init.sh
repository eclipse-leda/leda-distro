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
LEDA_DNS_PROXY_SERVICE_NAME="dns-proxy"
LEDA_NETWORK_DOMAIN="leda-network"
DNS_PROXY_IP=$(dig ${LEDA_DNS_PROXY_SERVICE_NAME}.${LEDA_NETWORK_DOMAIN} +short)
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectionAttempts=30 -q"

for TARGET in leda-x86 leda-arm64
do
    echo "Reconfiguring nameserver of ${TARGET} to use Docker DNS via dns-proxy container on ${DNS_PROXY_IP}"

    echo "Executing: $SSHCMD1" && $SSHCMD1
    SSHCMD1="ssh ${SSH_OPTS} root@${TARGET} systemd-resolve --interface eth0 --set-dns ${DNS_PROXY_IP} --set-domain ${LEDA_NETWORK_DOMAIN}"

    echo "Executing: $SSHCMD2" && $SSHCMD2
    SSHCMD2="ssh ${SSH_OPTS} root@${TARGET} systemctl restart systemd-resolved"

    echo "Deploying prometheus exporter to ${TARGET}"
    SSHCMD3="scp ${SSH_OPTS} -r nodeexporter/ root@${TARGET}:/data/server/manifests/nodeexporter/"
    echo "Executing: $SSHCMD3" && $SSHCMD3

    echo "Restarting deployments on ${TARGET}"
    SSHCMD7="ssh ${SSH_OPTS} root@${TARGET} /usr/local/bin/kubectl rollout restart deployment"
    echo "Executing: $SSHCMD7" && $SSHCMD7
done
echo "Done."