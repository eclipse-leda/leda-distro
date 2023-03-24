#!/bin/bash
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

# sudo apt install -y reprepro
# sudo apt install -y devscripts

# Todo: Get this from the latest package automatically
OS_RELEASE="dracon"
BASE_DIR="repo-root"

KEY_ID=`gpg --list-secret-key --with-subkey-fingerprint | tail -2 | xargs`

echo "GPG Key ID is: ${KEY_ID}"

# Create folder suppoed to be Apache httpd Document Root
# rm -rf ${BASE_DIR}

mkdir -p ${BASE_DIR}/conf

cat > ${BASE_DIR}/conf/distributions <<EOF
Origin: SDV
Label: SDV
Suite: unstable
Codename: ${OS_RELEASE}
Architectures: amd64 arm64
Components: main
Description: Apt repository for Software Defined Vehicle components
SignWith: ${KEY_ID}
EOF

#cat > ${BASE_DIR}/conf/options <<EOF
#verbose
#basedir /srv/repos/apt/debian
#ask-passphrase
#EOF

cat > ${BASE_DIR}/sdv.list <<EOF
deb https://sdvyocto.blob.core.windows.net/debian/ ${OS_RELEASE} main
EOF

# Now add the packages 
# find ../../build/tmp/deploy/deb/ -name "*.deb" -type f -print0 | while IFS= read -r -d $'\0' debFile; do
while read debFile; do
    echo "Processing ${debFile}"
    ./fix-version.sh ${debFile}
    reprepro --section misc --component main --priority optional -b ${BASE_DIR} includedeb ${OS_RELEASE} ${debFile}
done < packagelist
