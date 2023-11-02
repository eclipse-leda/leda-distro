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
${topic_pub_desiredstate}                 vehicleupdate/desiredstate
${desired_state_no_containers_filename}   robot-resources/desired-state-no-containers.json
${desired_state_filename}                 robot-resources/desired-state.json
@{containers}             sua    feedercan    seatservice-example    databroker    hvacservice-example

*** Test Cases ***
Containers are running
  [Documentation]    Containers are running upon system start
  Check containers presence    ${broker.uri}  ${broker.port}  @{containers}
  Expected containers status   ${broker.uri}  ${broker.port}  Running  @{containers}

Desired state to stop containers
  [Documentation]    Stop containers via empty desired state
  Publish from file    ${broker.uri}  ${broker.port}  ${topic_pub_desiredstate}  ${desired_state_no_containers_filename}
  Check desired state  ${broker.uri}  ${broker.port}

Desired state to start containers
  [Documentation]    Containers running via full desired state
  Publish from file    ${broker.uri}  ${broker.port}  ${topic_pub_desiredstate}  ${desired_state_filename}
  Check desired state  ${broker.uri}  ${broker.port}
