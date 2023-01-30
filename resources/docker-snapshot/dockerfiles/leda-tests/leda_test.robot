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

*** Settings ***
Documentation     This is a test for Self Update Agent
...               using mosquitto
...
...
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process

*** Variables ***
${http.uri}                 192.168.7.1
${broker.uri}               192.168.7.2
${broker.port}              31883
${topic_pub}                selfupdate/desiredstate
${topic_sub}                selfupdate/#
${log_messages}             False
${start_update_filename}    start-update-example.yaml

*** Test Cases ***
Self Update Agent Test
  Trigger to start update  ${broker.uri}    ${broker.port}    ${topic_pub}    ${start_update_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${log_messages}

Stop processes
  Terminate All Processes  kill=True
