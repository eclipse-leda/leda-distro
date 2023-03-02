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
Documentation     Self Update ${leda.target}
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process

Test Timeout       5 minutes

*** Variables ***
${http.uri}                 192.168.7.1
${broker.uri}               192.168.7.2
${broker.port}              31883
${topic_pub}                selfupdate/desiredstate
${topic_sub}                selfupdate/#
${start_update_filename}    robot-resources/start-update-example-x86.yaml
${get_state_filename}       robot-resources/get_state.json
${update_success_regex}    ([.\\s\\S]*)("UPDATE_SUCCESS")([\\s\\S.]*)
${sua_alive_regex}    ([.\\s\\S]*)(timestamp)([\\s\\S.]*)
${topic_currentstate}      selfupdate/currentstate/get

*** Test Cases ***
Wait for SUA alive
    Wait Until Keyword Succeeds    5m    3s   Verify SUA is alive    ${broker.uri}    ${broker.port}    ${topic_currentstate}    ${get_state_filename}    ${sua_alive_regex}

Self Update Agent Test
  [Documentation]    Install update bundle
  # Wait for max five minutes until SUA is deployed and running
  Wait Until Keyword Succeeds    5m    3s   Verify SUA is alive    ${broker.uri}    ${broker.port}    ${topic_currentstate}    ${get_state_filename}    ${sua_alive_regex}
  Trigger to start update  ${broker.uri}    ${broker.port}    ${topic_pub}    ${start_update_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${update_success_regex}
