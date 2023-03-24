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

TARGET="$1"

if ! dpkg-deb --field ${TARGET} Version; then
    echo "Trying to fix version number for ${TARGET}"
    TMPDIR=$(mktemp --directory --tmpdir)
    echo ${TMPDIR}
    dpkg-deb -R ${TARGET} ${TMPDIR}
    VERSION="0.0.1"
    sed -i -e "s,^Version: .*,Version: $VERSION," ${TMPDIR}/DEBIAN/control
    dpkg-deb -b ${TMPDIR} ${TARGET}
fi
