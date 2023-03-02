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
Documentation     This is a resource file, that can contain variables and keywords.
...               Keywords defined here can be used where this file is loaded.

Library  MQTTLibrary
Library  yaml
Library  Collections
Library  OperatingSystem
Library  Process
Library  String

*** Variables ***
${message_wait_timeout_seconds}    120
${leda.sshport}                    2222

*** Keywords ***

Verify SUA is alive
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}    ${get_current_state_filename}    ${payload_regex}
  ${message}=  Get File  ${get_current_state_filename}
  Connect  ${broker.uri}  ${broker.port}
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}
  Log    ${payload_regex}
  Subscribe And Validate  selfupdate/currentstate    qos=1    payload=${payload_regex}    timeout=10

Trigger to start update
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}    ${start_update_filename}
  ${version_id}=    Leda Execute OK              cat /etc/os-release | grep ^VERSION_ID= | cut -c12-
  ${template}=      Get File  ${start_update_filename}
  # Replace ${VERSION_ID} dynamically with the actual version on the device for easier testing
  ${message}=       Replace String      ${template}      \${VERSION_ID}   ${version_id.stdout}
  # Workaround for testing purposes - override current os-release version
  ${fakeversion}=   Generate Random String  8
  ${result}=    Leda Execute OK   echo VERSION_ID=${fakeversion} > /etc/os-release
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}
  RETURN    ${version_id.stdout}

Connect and Subscribe to Listen
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_sub}    ${payload_regex}
  Connect  ${broker.uri}  ${broker.port}
  Subscribe And Validate  ${topic_sub}    qos=1    payload=${payload_regex}    timeout=${message_wait_timeout_seconds}

Get RAUC Boot Primary Slot
    [Documentation]    Get current booted RAUC primary (rootfs.0, rootfs.1)
    ${result}=    Leda Execute    rauc status --output-format=json
    Log    RAUC RC: ${result.rc}
    Log    RAUC Output: ${result.stdout}
    Log    RAUC Error: ${result.stderr}
    ${json}=    Evaluate    json.loads("""${result.stdout}""")
    ${rauc_boot_primary}=    Set variable  ${json['boot_primary']}
    RETURN    ${rauc_boot_primary}

Get Current RAUC Boot Name
    [Documentation]    Get current booted RAUC slot (SDV_A, SDV_B)
    ${result}=    Leda Execute    rauc status --output-format=json
    ${json}=    Evaluate    json.loads("""${result.stdout}""")
    ${rauc_booted_slot}=    Set variable  ${json['booted']}
    RETURN    ${rauc_booted_slot}

Set Next RAUC Boot Slot
    [Documentation]    Set next slot to boot (rootfs.0, rootfs.1)
    [Arguments]    ${nextslot}
    ${result}=    Leda Execute    rauc status mark-active ${nextslot}
    Should Be Equal As Integers 	${result.rc} 	${0}

Leda Reboot
    [Documentation]    Blocks until reboot is finished
    Leda Execute       reboot now
    Sleep    15s
    Wait Until Keyword Succeeds    3 min    5 sec    SSH Port Should Be Open

SSH Port Should Be Open
    [Documentation]    Tests if SSH port is open
    ${result}=    Leda Execute    echo Welcome back
    Should Match    ${result.stdout}    Welcome back

Leda Execute OK
    [Documentation]    Execute a command via SSH and expect success
    [Arguments]        ${command}
    ${result}=         Leda Execute    ${command}
    IF  ${result.rc} > 0
        FAIL    Command failed with rc ${result.rc}: ${result.stderr} ${result.stdout}
    END
    RETURN    ${result}

Leda Execute
    [Documentation]    Executing commands inside Docker via remote SSH
    [Arguments]        ${command}
    ${expanded}=       Format String    ssh {sshopts} -p {port} root\@{hostname} "{command}"
    ...    sshopts=-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o ConnectionAttempts=15
    ...    port=${leda.sshport}
    ...    hostname=${leda.target.hostname}
    ...    command=${command}
    ${result}=    Run Process    bash    -c    ${expanded}    shell=True
    Log    ${result.rc}
    Log    ${result.stdout}
    Log    ${result.stderr}
    RETURN    ${result}
