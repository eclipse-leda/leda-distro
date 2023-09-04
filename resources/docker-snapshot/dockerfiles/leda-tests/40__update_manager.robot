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
Documentation     Update Manager ${leda.target}
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process

Test Timeout       10 minutes

*** Variables ***

${sua_alive_regex}           ([.\\s\\S]*)("self-update-agent")([\\s\\S.]*)
${topic_pub_currentstate}   selfupdate/currentstate/get
${topic_sub_currentstate}   selfupdate/currentstate
${get_state_filename}       robot-resources/get_state.json

${topic_pub_desiredstate}   vehicleupdate/desiredstate
${desired_state_no_containers_filename}     robot-resources/desired-state-no-containers.json
${desired_state_filename}                   robot-resources/desired-state.json
@{containers}           databroker    feedercan    seatservice-example    hvacservice-example

*** Test Cases ***

Check containers running
  [Documentation]    Check containers running
  Wait Until Keyword Succeeds  5m  3s  Verify SUA is alive  ${broker.uri}  ${broker.port}  ${topic_pub_currentstate}  ${topic_sub_currentstate}  ${get_state_filename}  ${sua_alive_regex}
  ${result}=     Check containers status  ${broker.uri}  ${broker.port}  Running  @{containers}
  Should Be Empty    ${result}

Stop containers
  [Documentation]    Stop containers
  Publish command from file    ${broker.uri}    ${broker.port}    ${topic_pub_desiredstate}    ${desired_state_no_containers_filename}
  ${result}=     Check containers status  ${broker.uri}  ${broker.port}  Stopped  @{containers}
  Should Be Empty    ${result}

Bring all containers running
  [Documentation]    Bring all containers running
  Publish command from file    ${broker.uri}    ${broker.port}    ${topic_pub_desiredstate}    ${desired_state_filename}
  ${result}=     Check containers status  ${broker.uri}  ${broker.port}  Running  @{containers}
  Should Be Empty    ${result}
