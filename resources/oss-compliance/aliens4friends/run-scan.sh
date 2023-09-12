#!/bin/bash

BASE_DIR="../../../build/tmp/deploy"
ALIENSRC_SOURCE_DIR="${BASE_DIR}/aliensrc"
TINFOILHAT_SOURCE_DIR="${BASE_DIR}/tinfoilhat"
A4F_BIN="docker compose run toolchain"

find "$ALIENSRC_SOURCE_DIR" -type f -print0 |
  while mapfile -d '' -n 10 SOMEFILES && [ ${#SOMEFILES[@]} -gt 0 ]; do
    # Iterate indexes in the list
    A4F_SESSION="session-${RANDOM}"
    echo "Session: ${A4F_SESSION}"
    ${A4F_BIN} config
    a4f session -ns ${A4F_SESSION}
    for ALIENSRC_PATH in "${SOMEFILES[@]}"; do
      BASE_FILE=$(basename ${ALIENSRC_PATH} .aliensrc)
      TINFOILHAT_PATH="${TINFOILHAT_SOURCE_DIR}/${BASE_FILE}.tinfoilhat.json"
      echo "Processing:  ${BASE_FILE}"
      echo " AliensRC:   ${ALIENSRC_PATH}"
      echo " Tinfoilhat: ${TINFOILHAT_PATH}"
      ${A4F_BIN} add -s ${A4F_SESSION} ${ALIENSRC_PATH}
      ${A4F_BIN} add -s ${A4F_SESSION} ${TINFOILHAT_PATH}
    done

    ${A4F_BIN} listpool --session ${A4F_SESSION} --filetype ALIENSRC
    ${A4F_BIN} match -s ${A4F_SESSION}
    ${A4F_BIN} snapmatch -s ${A4F_SESSION}
    ${A4F_BIN} scan -s ${A4F_SESSION}
    ${A4F_BIN} delta -s ${A4F_SESSION}
    ${A4F_BIN} spdxdebian -s ${A4F_SESSION}
    ${A4F_BIN} spdxalien -s ${A4F_SESSION}
    ${A4F_BIN} upload --folder leda -s ${A4F_SESSION}
    ${A4F_BIN} fossy -s ${A4F_SESSION}
    ${A4F_BIN} fossy --sbom -s ${A4F_SESSION}
    ${A4F_BIN} harvest -s ${A4F_SESSION} --report-name eclipse-leda.aliens4friends.json

  done
