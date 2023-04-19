#!/bin/sh
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

docker build --tag tinfoilhat/tinfoilhat -f Dockerfile .

# Run tinfoilhat
# Note:
# - BitBake Sanity checker requires that the absolute paths of the TMP_DIR stays the same,
#   so we need to mount the host path to the same path inside the container and let
#   the entrypoint script know about them as well, so that i can adapt the PYTHONPATH variable correctly.
docker run --rm -it \
    --volume ${CODESPACE_VSCODE_FOLDER}:${CODESPACE_VSCODE_FOLDER} \
    tinfoilhat/tinfoilhat \
    "${CODESPACE_VSCODE_FOLDER}" "$(git describe --tags)"
