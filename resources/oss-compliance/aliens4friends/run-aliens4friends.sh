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
# See https://gitlab.eclipse.org/eclipse/oniro-compliancetoolchain/toolchain/aliens4friends.git

# git clone https://gitlab.eclipse.org/eclipse/oniro-compliancetoolchain/toolchain/aliens4friends.git aliens4friends
# cd aliens4friends
# docker compose run --rm toolchain a4f config > .env

docker compose build --build-arg GITHUB_BOT_AUTH=${GITHUB_TOKEN} --progress plain
docker compose down
docker compose up -d --wait

docker compose run toolchain a4f config
docker compose run toolchain a4f session -ns MYSESSION
docker compose run toolchain a4f add -s MYSESSION /deploy/aliensrc/zlib-1.2.11-r0-9b0214ed.aliensrc
docker compose run toolchain a4f add -s MYSESSION /deploy/tinfoilhat/zlib-1.2.11-r0-9b0214ed.tinfoilhat.json
docker compose run toolchain a4f listpool --session MYSESSION --filetype ALIENSRC
docker compose run toolchain a4f match -s MYSESSION
docker compose run toolchain a4f snapmatch -s MYSESSION
docker compose run toolchain a4f scan -s MYSESSION
docker compose run toolchain a4f delta -s MYSESSION
docker compose run toolchain a4f spdxdebian -s MYSESSION
docker compose run toolchain a4f spdxalien -s MYSESSION
docker compose run toolchain a4f upload --folder leda -s MYSESSION
docker compose run toolchain a4f fossy -s MYSESSION
docker compose run toolchain a4f harvest -s MYSESSION --report-name eclipse-leda.aliens4friends.json

# a4f config
# a4f session -ns MYSESSION
# a4f add -s MYSESSION /deploy/aliensrc/zlib-1.2.11-r0-9b0214ed.aliensrc
# a4f add -s MYSESSION /deploy/tinfoilhat/zlib-1.2.11-r0-9b0214ed.tinfoilhat.json
# a4f listpool --session MYSESSION --filetype ALIENSRC
# a4f match -s MYSESSION
# a4f snapmatch -s MYSESSION
# a4f scan -s MYSESSION
# a4f delta -s MYSESSION
# a4f spdxdebian -s MYSESSION
# a4f spdxalien -s MYSESSION
# a4f upload --folder leda -s MYSESSION
# a4f fossy -s MYSESSION
# a4f harvest -s MYSESSION --report-name eclipse-leda.aliens4friends.json

# Run the toolchain shell:
# docker compose rm toolchain
# docker compose run --volume "/workspaces/leda-distro-fork/build/tmp/deploy/:/deploy" toolchain
# docker compose run toolchain

# Example commands inside the docker container
# a4f config
# a4f session -ns MYSESSION
# a4f add -s MYSESSION /deploy/aliensrc/zlib-1.2.11-r0-9b0214ed.aliensrc
# a4f add -s MYSESSION /deploy/tinfoilhat/zlib-1.2.11-r0-9b0214ed.tinfoilhat.json
# a4f listpool --session MYSESSION --filetype ALIENSRC
# a4f match -s MYSESSION
# a4f snapmatch -s MYSESSION
# a4f scan -s MYSESSION
# a4f delta -s MYSESSION
# a4f spdxdebian -s MYSESSION
# a4f spdxalien -s MYSESSION
# a4f upload --folder leda -s MYSESSION
# a4f fossy -s MYSESSION
# a4f harvest -s MYSESSION --report-name eclipse-leda.aliens4friends.json
    
# docker compose run --volume "/workspaces/leda-distro-fork/build/tmp/deploy/aliensrc:/build/aliensrc" --rm toolchain a4f add -s MYSESSION /build/aliensrc/zlib-1.2.11-r0-9b0214ed.aliensrc
# docker compose run --volume "/workspaces/leda-distro-fork/build/tmp/deploy/tinfoilhat:/build/tinfoilhat" --rm toolchain a4f add -s MYSESSION /build/tinfoilhat/zlib-1.2.11-r0-9b0214ed.tinfoilhat.json
# docker compose run --rm toolchain a4f listpool --session MYSESSION --filetype ALIENSRC
# docker-compose run --rm toolchain scancode
# docker compose run --rm toolchain a4f --help
# docker-compose run --rm toolchain spdxtool
# aliens4friends config > .env
# docker compose run --rm toolchain a4f match -s MYSESSION
# docker compose run --volume "/workspaces/leda-distro-fork/build/tmp/deploy/:/deploy" --rm toolchain a4f add -s MYSESSION /deploy/aliensrc/
# docker compose run --volume "/workspaces/leda-distro-fork/build/tmp/deploy/:/deploy" --rm toolchain a4f add -s MYSESSION /deploy/tinfoilhat/*

