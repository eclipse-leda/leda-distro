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
# Download latest release and test-drive the qemu startup scripts
#
# the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# the temp directory used, within $DIR
# omit the -p parameter to create a temporal directory in the default location
WORK_DIR=`mktemp -d -t tmp.releasevalidation.XXXXX -p "$DIR"`

# check if tmp dir was created
if [[ ! "$WORK_DIR" || ! -d "$WORK_DIR" ]]; then
  echo "Could not create temp dir"
  exit 1
fi

# deletes the temp directory
function cleanup {      
  #rm -rf "$WORK_DIR"
  echo "Deleted temp working directory $WORK_DIR"
}

# register the cleanup function to be called on the EXIT signal
trap cleanup EXIT

function runtest {
  ./run-leda.sh &
  BG_PID=$!
  echo "Background pid for run script is ${BG_PID}"
  sleep 10
  x=1
  max=20
  test=0
  while [ $x -le $max ]
  do
    echo "Hammer time .. $x"
    ssh -o StrictHostKeyChecking=off -o ConnectTimeout=5s -p 2222 root@localhost "(shutdown now &); exit"
    RC_SSH_1=$?
    echo RC_SSH_1=${RC_SSH_1}
    if [ ${RC_SSH_1} -eq 0 ]
    then
      echo "Test is done via slirp, exiting"
      test=1
      break
    fi
    ssh -o StrictHostKeyChecking=off -o ConnectTimeout=5s root@192.168.7.2 "(shutdown now &); exit"
    RC_SSH_2=$?
    echo RC_SSH_2=${RC_SSH_2}
    if [ ${RC_SSH_2} -eq 0 ]
    then
      echo "Test is done via tap, exiting"
      test=1
      break
    fi
    x=$(( $x + 1 ))
  done

  if [ ${test} -eq 0 ]
  then
    echo "Unable to connect via SSH, failing test and killing qemu"
    kill ${BG_PID}
    sudo pkill -f qemu-system
    sleep 1
  else 
    echo "Test successful, waiting for qemu to stop"
    wait ${BG_PID}
    echo "Done waiting."
    sleep 1
  fi

}

function performtest {
    local ARTIFACT=$1
    echo "Testing $ARTIFACT"
    mkdir -p $WORK_DIR/$ARTIFACT
    pushd $WORK_DIR/$ARTIFACT
    echo "Downloading latest build artifact..."
    gh release download v0.0.10 --pattern $ARTIFACT
    echo "Uncompressing..."
    tar xf $ARTIFACT
    echo "Running qemu..."
    runtest
    popd
}

performtest "eclipse-leda-qemu-arm64.tar.xz"
performtest "eclipse-leda-qemu-arm.tar.xz"
performtest "eclipse-leda-qemu-x86_64.tar.xz"
