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
${topic_pub_desiredstate}   vehicleupdate/desiredstate
# Used to get bundle version
${topic_sub_selfupdate}     selfupdate/desiredstatefeedback
${identified_success_regex}  ([.\\s\\S]*)("IDENTIFIED")([\\s\\S.]*)

*** Test Cases ***
Wait for SUA running
  [Documentation]    SUA is running upon system start
  Check containers presence   ${broker.uri}  ${broker.port}  sua
  Expected containers status  ${broker.uri}  ${broker.port}  Running  sua

Self Update Test
  [Documentation]    Install update bundle
  ${expected_version}=  Trigger to start update  ${broker.uri}  ${broker.port}  ${topic_pub_desiredstate}  ${topic_sub_selfupdate}  ${start_update_filename}  ${identified_success_regex}

  Check desired state   ${broker.uri}  ${broker.port}

  ${result}=    Leda Execute OK   echo VERSION_ID=${expected_version} > /etc/os-release
  ${result_status}=      Leda Execute OK      rauc status --detailed --output-format=json
  ${json}=               Evaluate             json.loads("""${result_status.stdout}""")
  ${installed_json}=     Get Value From Json    ${json}    $..slots[*][?(@.slot_status.status=='ok')]     fail_on_empty=${True}
  Should Match           ${installed_json[0]['slot_status']['bundle']['version']}   ${expected_version}