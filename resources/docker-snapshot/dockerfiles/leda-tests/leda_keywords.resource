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
Library  JSONLibrary
Library  yaml
Library  Collections
Library  OperatingSystem
Library  Process
Library  String

*** Variables ***
${leda.sshport}                    2222
${json_query}     $..payload[*].softwareNodes[?(@.id=='containers:{container}')].parameters[?(@.key=='status')].value

*** Keywords ***

Publish until met
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}   ${topic_sub}   ${message}   ${payload_regex}
  Connect  ${broker.uri}  ${broker.port}
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}
  Subscribe And Validate  ${topic_sub}    qos=1    payload=${payload_regex}    timeout=10

Trigger to start update
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}  ${topic_sub}  ${start_update_filename}   ${payload_regex}
  ${version_id}=    Leda Execute OK              cat /etc/os-release | grep ^VERSION_ID= | cut -c12-
  ${template}=      Get File  ${start_update_filename}
  # Replace ${VERSION_ID} dynamically with the actual version on the device for easier testing
  ${message}=       Replace String      ${template}      \${VERSION_ID}   ${version_id.stdout}
  # Workaround for testing purposes - override current os-release version
  ${fakeversion}=   Generate Random String  8
  ${result}=    Leda Execute OK   echo VERSION_ID=${fakeversion} > /etc/os-release
  Wait Until Keyword Succeeds  3m  3s  Publish until met  ${broker.uri}  ${broker.port}  ${topic_pub}  ${topic_sub}  ${message}  ${payload_regex}
  RETURN    ${version_id.stdout}

Publish command from file
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}    ${filename}
  ${message}=      Get File  ${filename}
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}

Connect and Subscribe to Listen
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_sub}    ${payload_regex}    ${message_wait_timeout_seconds}
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

View json
    [Documentation]    For debug purposes
    [Arguments]        ${message}
    ${command}=       Format String  echo '{message}' | jq .
    ...    message=${message}
    ${result}=    Run Process    bash    -c    ${command}    shell=True
    Log to console    ${result.stdout}

Check containers status
    [Documentation]    Checks list of containers for status (Running, Missing, Any and Stopped)
    [Arguments]    ${broker.uri}    ${broker.port}   ${status}   @{list}
    Connect    ${broker.uri}    ${broker.port} 
    @{listNext}      Create List    @{list}
    TRY
      WHILE   ${listNext} != @{EMPTY}   limit=100
        Publish command from file    ${broker.uri}    ${broker.port}
        ...   containersupdate/currentstate/get
        ...   robot-resources/update-state.json
        @{messagelist}=   Subscribe   containersupdate/currentstate   qos=1   timeout=1    limit=1
        Length should be  ${messagelist}   1
        ${json_string}=   Get From List   ${messagelist}    0
        ${message}=	      Convert String to JSON	   ${json_string}
        @{listCurrent}    Create List    @{listNext}
        FOR    ${container}    IN    @{listCurrent}
          ${jq}=    Format String  ${json_query}
          ...    container=${container}
          ${result}=      Get Value From Json    ${message}    ${jq}
          IF  ${result} == @{EMPTY}
            IF  '${status}' == 'Missing'
              Remove values from list    ${listNext}   ${container}
            END
            CONTINUE
          END
          Length should be  ${result}   1
          ${result}=      Get From List   ${result}    0
          IF       '${result}' == '${status}'
            Remove values from list    ${listNext}   ${container}
          ELSE IF  '${status}' == 'Any'
            Remove values from list    ${listNext}   ${container}
          END
        END
        Unsubscribe     containersupdate/currentstate
      END
    EXCEPT    WHILE loop was aborted    type=start
      Log    The loop did not finish within the limit.
    END   
    Disconnect
    RETURN    ${listNext}

Expected containers status
    [Documentation]    Can rise an error after call to Check containers status
    ...     Used from Wait Until Keyword Succeeds when needed
    [Arguments]    ${broker.uri}    ${broker.port}   ${status}   @{list}
    ${result}=     Check containers status  ${broker.uri}  ${broker.port}   ${status}   @{list}
    Should Be Empty    ${result}    msg=Container(s) ${result} must have ${status} status

Check containers presence
    [Documentation]    Checks list of containers presence in any status
    [Arguments]    ${broker.uri}    ${broker.port}   @{list}
    Wait Until Keyword Succeeds  5m  30s  Expected containers status  ${broker.uri}  ${broker.port}   Any   @{list}

Check desired state
    [Arguments]    ${broker.uri}    ${broker.port}
    Connect    ${broker.uri}    ${broker.port}
    WHILE   True   limit=50        
      @{messagelist}=   Subscribe   vehicleupdate/desiredstatefeedback   qos=1   timeout=120    limit=1
      Length should be  ${messagelist}   1
      ${json_string}=   Get From List   ${messagelist}    0
      ${message}=	   Convert String to JSON	   ${json_string}
      ${result}=     Get Value From Json    ${message}    $..payload['status']
      ${msg}=        Get Value From Json    ${message}    $..payload['message']
      ${result}=     Get From List   ${result}    0
      Unsubscribe    vehicleupdate/desiredstatefeedback
      Log  ${result} ${msg}
      IF  'COMPLETED' in '${result}'
        Disconnect
        RETURN
      ELSE IF   'FAILED' in '${result}' or 'INCOMPLETE' in '${result}'
        Disconnect
        ${msg}=  Get Value From Json    ${message}    $..payload['message']
  	    FAIL  Desired state is ${result} (${msg})
        RETURN
      END
    END
    Disconnect
    FAIL  Too many attempts. Limit was reached
