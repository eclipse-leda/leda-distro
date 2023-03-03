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

Test Timeout       10 minutes

*** Variables ***
${leda.target}                 local
${leda.target.hostname}        localhost
${leda.sshport}                2001

*** Test Cases ***

SDV Containers Exist
    [Documentation]          SDV containers up and running
    Verify Leda Containers
    ...     sua
    ...     databroker
    ...     vum
    ...     feedercan
    ...     seatservice-example
    ...     hvacservice-example

SDV Unconfigured Containers
    [Documentation]          Created in any state
    Container Any State
    ...     cloudconnector

*** Keywords ***
Verify Leda Containers
    [Documentation]          Verify if container is created and running
    [Arguments]              @{containernames}
    Wait Until Keyword Succeeds    3m    10s    Container Exists     @{containernames}
    Leda Local Container Running    @{containernames}

Container Any State
    [Documentation]          Verify if container is created (no matter which state)
    [Arguments]              @{containernames}
    Wait Until Keyword Succeeds    2m    10s    Container Exists     @{containernames}

Leda Local Container Running
    [Documentation]          Ask kanto-cm if container with name is in running state
    [Arguments]              @{containernames}
    FOR     ${containername}    IN    @{containernames}
        Log    Testing container ${containername}
        ${result}=               Leda Execute    kanto-cm get --name ${containername} | jq '.state.running'
        Should Match             ${result.stdout} 	true    msg=Container ${containername} exists but is not running   values=False
    END

Container Exists
    [Documentation]          Ask kanto-cm if container with name exists
    [Arguments]              @{containernames}
    FOR     ${containername}    IN    @{containernames}
        Log    Testing container ${containername}
        ${result}=         Leda Execute    kanto-cm get --name ${containername}
        IF  ${result.rc} > 0
            FAIL    Container ${containername} missing
        END
    END
