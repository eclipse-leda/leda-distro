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
Documentation     Basic OS ${leda.target}
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
Execute Shell Command
    [Documentation]    Simple shell command
    ${result}=         Leda Execute OK     echo Welcome Leda
    Should Match       ${result.stdout}    Welcome Leda

Check OS Name
    [Documentation]    Leda distro name
    ${result}=         Leda Execute OK        cat /etc/os-release | grep ^NAME=
    Set Test Message   OS is ${result.stdout}
    Should Match       ${result.stdout}       NAME="Eclipse Leda"

Check OS Pretty Name
    [Documentation]        Distro pretty name
    ${result}=             Leda Execute OK          cat /etc/os-release | grep ^PRETTY_NAME=
    Set Test Message       OS is ${result.stdout}
    Should Not Be Empty    ${result.stdout}

Check OS Version
    [Documentation]        Distro version
    ${result}=             Leda Execute OK              cat /etc/os-release | grep ^VERSION_ID=
    Set Test Message       Version is ${result.stdout}
    Should Not Be Empty    ${result.stdout}

Check Image Version
    [Documentation]        Distro image version
    ${result}=             Leda Execute OK   cat /etc/os-release | grep ^IMAGE_VERSION=
    Set Test Message       Image is ${result.stdout}
    Should Not Be Empty    ${result.stdout}

Check Build ID
    [Documentation]        Distro build id
    ${result}=             Leda Execute OK   cat /etc/os-release | grep ^BUILD_ID=
    Set Test Message       Build id is ${result.stdout}
    Should Not Be Empty    ${result.stdout}

Check machine platform
    [Documentation]        Machine architecture
    ${result}=             Leda Execute OK   uname -m
    Set Test Message       Architecture is ${result.stdout}
    Should Not Be Empty    ${result.stdout}

Check systemctl
    [Documentation]        Is systemd installed?
    ${result}=             Leda Execute OK   command -v systemctl
    Should Be Equal As Integers 	${result.rc} 	${0}

Check jq
    [Documentation]        Is jq installed?
    ${result}=             Leda Execute OK   command -v jq
    Should Be Equal As Integers 	${result.rc} 	${0}

Check databroker-cli
    [Documentation]        Is Kuksa Databroker CLI installed?
    ${result}=             Leda Execute OK   command -v databroker-cli
    Should Be Equal As Integers 	${result.rc} 	${0}

Check kanto-cm
    [Documentation]        Container Management service running?
    ${result}=             Leda Execute   systemctl is-active container-management.service
    IF    ${result.rc} > 0
        Set Test Message   container-management.service is in ${result.stdout} state
    END
    Should Match           ${result.stdout} 	active

Check mqtt broker
    [Documentation]        Mosquitto service running?
    ${result}=             Leda Execute OK   systemctl is-active mosquitto.service
    Should Match 	       ${result.stdout} 	active

Check sdv-health
    [Documentation]        Scripts returns no error
    ${result}=             Leda Execute OK   sdv-health
    Should Be Equal As Integers 	${result.rc} 	${0}
