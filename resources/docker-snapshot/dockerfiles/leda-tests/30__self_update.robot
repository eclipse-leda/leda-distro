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
Library  JSONLibrary

Test Timeout       10 minutes

*** Variables ***
${leda.target}                 local
${leda.target.hostname}        localhost
${leda.sshport}                2001

${broker.uri}               127.0.0.1
${broker.port}              1884
${topic_pub}                selfupdate/desiredstate
${topic_pub_command}        selfupdate/desiredstate/command
${topic_sub}                selfupdate/desiredstatefeedback
${start_update_filename}    robot-resources/start-update-example-x86.json
${download_filename}        robot-resources/download-command.json
${update_filename}          robot-resources/update-command.json
${activate_filename}        robot-resources/activate-command.json
${cleanup_filename}         robot-resources/cleanup-command.json
${identified_success_regex}  ([.\\s\\S]*)("IDENTIFIED")([\\s\\S.]*)
${download_success_regex}    ([.\\s\\S]*)("DOWNLOAD_SUCCESS")([\\s\\S.]*)
${update_success_regex}      ([.\\s\\S]*)("UPDATE_SUCCESS")([\\s\\S.]*)
${activation_success_regex}  ([.\\s\\S]*)("ACTIVATION_SUCCESS")([\\s\\S.]*)
${cleanup_success_regex}     ([.\\s\\S]*)("COMPLETE")([\\s\\S.]*)

*** Test Cases ***
Wait for SUA alive
  Check containers presence   ${broker.uri}  ${broker.port}  sua
  Expected containers status  ${broker.uri}  ${broker.port}  Running  sua

Self Update Test
  [Documentation]    Install update bundle
  Log To Console  \nGet Version and Start Update...
  ${expected_version}=  Trigger to start update  ${broker.uri}  ${broker.port}  ${topic_pub}  ${topic_sub}  ${start_update_filename}  ${identified_success_regex}

  Log To Console  Download...
  Publish command from file   ${broker.uri}    ${broker.port}    ${topic_pub_command}    ${download_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${download_success_regex}    120

  Log To Console  Update...
  Publish command from file   ${broker.uri}    ${broker.port}    ${topic_pub_command}    ${update_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${update_success_regex}    120

  Log To Console  Activate...
  Publish command from file   ${broker.uri}    ${broker.port}    ${topic_pub_command}    ${activate_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${activation_success_regex}    30

  Log To Console  Cleanup...
  Publish command from file   ${broker.uri}    ${broker.port}    ${topic_pub_command}    ${cleanup_filename}
  Connect and Subscribe to Listen   ${broker.uri}    ${broker.port}    ${topic_sub}    ${cleanup_success_regex}    5

  Log To console  Finalize
  ${result}=    Leda Execute OK   echo VERSION_ID=${expected_version} > /etc/os-release
  ${result_status}=      Leda Execute OK      rauc status --detailed --output-format=json
  ${json}=               Evaluate             json.loads("""${result_status.stdout}""")
  ${installed_json}=     Get Value From Json    ${json}    $..slots[*][?(@.slot_status.status=='ok')]     fail_on_empty=${True}
  Should Match           ${installed_json[0]['slot_status']['bundle']['version']}   ${expected_version}