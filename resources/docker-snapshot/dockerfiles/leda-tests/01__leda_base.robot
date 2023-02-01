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
Documentation     This is a test for basic operating system status
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process
Library  String

*** Variables ***
${leda.target}        leda-x86.leda-network
${leda.sshport}        2222

*** Test Cases ***
Execute Command In Leda Shell
    [Documentation]    Execute a simple command in Leda    
    ${result}=    Leda Execute    echo Welcome Leda
    Should Match 	${result.stdout} 	Welcome Leda

Check OS Version
    [Documentation]    Checking the Leda version name
    ${result}=    Leda Execute    cat /etc/os-release | grep ^NAME=
    Should Match 	${result.stdout} 	NAME="Eclipse Leda"

Check kanto-cm
    [Documentation]    Is Kanto Container Management up and running?
    ${result}=    Leda Execute    systemctl is-active container-management.service
    Should Match 	${result.stdout} 	active

Check sdv-health
    [Documentation]    SDV Health working
    ${result}=    Leda Execute    sdv-health
    Should Be Equal As Integers 	${result.rc} 	${0}

Check RAUC Status
    [Documentation]    Is current booted partition SDV_A
    ${result}=    Leda Execute    rauc status --output-format=json
    ${json}=    Evaluate    json.loads("""${result.stdout}""")
    ${rauc_booted_slot}=    Set variable  ${json['booted']}
    ${rauc_compatible}=    Set variable  ${json['compatible']}
    ${rauc_boot_primary}=    Set variable  ${json['boot_primary']}
    Should Be Equal As Integers 	${result.rc} 	${0}
    Should Match 	${rauc_booted_slot} 	SDV_A
    Should Match 	${rauc_compatible} 	Eclipse Leda
    Should Match 	${rauc_boot_primary} 	rootfs.0
