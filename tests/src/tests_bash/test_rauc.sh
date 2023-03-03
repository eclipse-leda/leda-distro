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

HTTP_PID=0

kill_http()
{
  if [ $HTTP_PID -ne 0 ]; then
    kill $HTTP_PID
    echo "Stop http server"
  fi
}

check_pods()
{
  echo "Check pods"
  local MOSQUITTO_RUNNING=$(timeout --preserve-status 5m ssh -q -o StrictHostKeyChecking=off -p 22 root@192.168.7.2 "/usr/local/bin/kubectl describe pod mosquitto" | grep "Status:"  | cut -d ':' -f 2 | xargs)
  if [ "$MOSQUITTO_RUNNING" != "Running" ]; then
    echo "Mosquitto Pod is not running"
    exit 1
  else
    echo "Mosquitto Pod is running"
  fi
  local SELFUPDATEAGENT_RUNNING=$(timeout --preserve-status 5m ssh -q -o StrictHostKeyChecking=off -p 22 root@192.168.7.2 "/usr/local/bin/kubectl describe pod selfupdateagent" | grep "Status:"  | cut -d ':' -f 2 | xargs)
  if [ "$SELFUPDATEAGENT_RUNNING" != "Running" ]; then
    echo "SelfUpdateAgent Pod is not running"
    exit 1
  else
    echo "SelfUpdateAgent Pod is running"
  fi
}

create_file()
{
  echo "Create start-update-example.yaml file"
  echo 'apiVersion: "sdv.eclipse.org/v1"' > start-update-example.yaml
  echo 'kind: SelfUpdateBundle' >> start-update-example.yaml
  echo 'metadata:' >> start-update-example.yaml
  echo '  name: self-update-bundle-example:' >> start-update-example.yaml
  echo 'spec:' >> start-update-example.yaml
  echo '  bundleName: swdv-qemux86-64-build42' >> start-update-example.yaml
  echo '  bundleVersion: v1beta3' >> start-update-example.yaml
  echo '  bundleDownloadUrl: http://192.168.7.1:8000/sdv-rauc-bundle-minimal-qemux86-64.raucb' >> start-update-example.yaml
  echo '  bundleTarget: base' >> start-update-example.yaml
}

start_http()
{
  echo "Start http server"
  cd tmp/deploy/images/qemux86-64
  nohup python3 -m http.server --bind 192.168.7.1 > /dev/null 2>&1 &
  HTTP_PID=$!
  if [ $? -ne 0 ]; then
    echo "HTTP Server unable to start"
    exit 1
  fi
}

start_download()
{
  echo "Start download"
  mosquitto_pub -h 192.168.7.2 -p 31883 -t "selfupdate/desiredstate" -f start-update-example.yaml
  MQTT_SUB=$(timeout --preserve-status 1m mosquitto_sub -h 192.168.7.2 -p 31883 -t "selfupdate/#" -F "%j" | grep -m 1 "message: Entered Installed state")
  rm start-update-example.yaml
  if [ -z "$MQTT_SUB" ]; then
    kill_http
    echo "RAUC bundle installation failed"
    exit 1
  fi
}

check_rauc()
{
  echo "Start RAUC check"
  RAUC=$(ssh -q -o StrictHostKeyChecking=off -p 22 root@192.168.7.2 "rauc status --detailed --output-format=json" | jq '.slots[] ."rootfs.1" ."slot_status" ."bundle" ."compatible"')
  for RAUC in "Eclipse Leda"; do
    GOOD=$(ssh -q -o StrictHostKeyChecking=off -p 22 root@192.168.7.2 "rauc status --detailed --output-format=json" | jq '.slots[] ."rootfs.1" ."boot_status"')
    for GOOD in "good"; do
      echo "RAUC bundle installed"
      exit 0
    done
  done
}

echo "Starting installation ..."
check_pods
start_http
create_file
start_download
kill_http
#if check_rauc pass - we will exit with 0
check_rauc
echo "RAUC bundle installation status failed"
exit 1