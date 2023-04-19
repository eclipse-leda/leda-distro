#!/bin/sh

docker build --tag tinfoilhat/tinfoilhat -f Dockerfile .

#    --entrypoint /bin/bash \
docker run --rm -it \
    --volume ${CODESPACE_VSCODE_FOLDER}:/workspace \
    tinfoilhat/tinfoilhat
