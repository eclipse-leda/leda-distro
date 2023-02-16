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
Documentation     Containers on ${leda.target}
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process
Library  String

Test Timeout       2 minutes

*** Variables ***
${leda.target}                 local
${leda.target.hostname}        localhost
${leda.sshport}                2001

*** Test Cases ***

Check containers
    [Documentation]          SDV Core containers installed
    [Timeout]                30m
    Verify Leda Container    sua
    Verify Leda Container    databroker
    Verify Leda Container    vum

*** Keywords ***
Verify Leda Container
    [Documentation]          Verify if container is created and running
    [Arguments]              ${containername}
    Wait Until Keyword Succeeds    5m    10s    Leda Local Container Running    ${containername}

Leda Local Container Running
    [Documentation]          Ask kanto-cm if container with name is in running state
    [Arguments]              ${containername}
    ${result}=               Leda Execute    kanto-cm get --name ${containername} | jq '.state.running'
    Should Match             ${result.stdout} 	true
