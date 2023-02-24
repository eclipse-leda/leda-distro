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
Documentation     Rebooting ${leda.target}
Resource          leda_keywords.resource

Test Timeout      20 minutes

*** Variables ***
${leda.target}                 local
${leda.target.hostname}        localhost
${leda.sshport}                2001

*** Test Cases ***
Before Reboot
    [Documentation]        Expect current partition to be clean
    ${before_slot}         Get RAUC Boot Primary Slot
    ${before_name}         Get Current RAUC Boot Name
    Should Match           ${before_slot}        rootfs.0
    Should Match           ${before_name}        SDV_A

Simple Reboot
    [Documentation]        Expect simple reboot to boot into same slot
    ${before_slot}         Get RAUC Boot Primary Slot
    ${before_name}         Get Current RAUC Boot Name
    Leda Reboot
    ${after_slot}          Get RAUC Boot Primary Slot
    ${after_name}          Get Current RAUC Boot Name
    Should Match           ${after_slot}         ${before_slot}
    Should Match           ${after_name}         ${before_name}
    Set Test Message    Reboot from and into ${after_slot}

Boot Into Other Slot
    [Documentation]    Boot into the other slot
    ${before_slot}         Get RAUC Boot Primary Slot
    ${before_name}         Get Current RAUC Boot Name
    Set Next RAUC Boot Slot     other
    Leda Reboot
    ${after_slot}          Get RAUC Boot Primary Slot
    ${after_name}          Get Current RAUC Boot Name
    Should Not Match           ${after_slot}         ${before_slot}
    Should Not Match           ${after_name}         ${before_name}
    Set Test Message    Reboot from ${before_slot} into ${after_slot}
