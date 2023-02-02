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
  ${message}=  Get File  ${start_update_filename}
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}

Connect and Subscribe to Listen
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_sub}    ${payload_regex}
  Connect  ${broker.uri}  ${broker.port}
  Subscribe And Validate  ${topic_sub}    qos=1    payload=${payload_regex}    timeout=${message_wait_timeout_seconds}

Leda Execute
    [Documentation]    Executing commands inside Docker via remote SSH
    [Arguments]    ${command}
    ${expanded}= 	Format String 	ssh -p ${leda.sshport} ${leda.target} ${command}
    ${result}=    Run Process    bash    -c    ${expanded}    shell=True
    RETURN    ${result}
