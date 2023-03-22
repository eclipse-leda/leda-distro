#!/bin/bash

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
