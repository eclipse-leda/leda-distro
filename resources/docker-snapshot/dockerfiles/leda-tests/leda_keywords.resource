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

Trigger to start update
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_pub}    ${start_update_filename}
  ${message}=  Get File  ${start_update_filename}
  Publish Single  topic=${topic_pub}  payload=${message}  hostname=${broker.uri}  port=${broker.port}

Connect and Subscribe to Listen
  [Arguments]    ${broker.uri}    ${broker.port}    ${topic_sub}    ${log_messages}
  Connect  ${broker.uri}  ${broker.port}
  @{messages}  Subscribe  ${topic_sub}  qos=1  timeout=${message_wait_timeout_seconds}  limit=1000
  FOR  ${message}  IN  @{messages}
    IF  ${log_messages}
      Log to console  ${message}
    END
    ${contains}=  Evaluate  "UPDATE_SUCCESS" in """${message}"""
    Exit For Loop If  ${contains}  
  END
  Should Be True 	${contains} 	msg="Did not receive UPDATE_SUCCESS message"
