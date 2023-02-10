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

*** Test Cases ***
Simple Reboot
    [Documentation]        Expect simple reboot to boot into same slot
    ${before_slot}         Get RAUC Boot Primary Slot
    ${before_name}         Get Current RAUC Boot Name
    ${before_next_name}    Get Next RAUC Boot Name
    Should Match           ${before_slot}        rootfs.0
    Should Match           ${before_name}        SDV_A
    Should Match           ${before_next_name}   SDV_A

    Leda Reboot

    ${after_slot}          Get RAUC Boot Primary Slot
    ${after_name}          Get Current RAUC Boot Name
    ${after_next_name}     Get Next RAUC Boot Name
    Should Match           ${after_slot}         rootfs.0
    Should Match           ${after_name}         SDV_A
    Should Match           ${after_next_name}    SDV_A

Boot Into Second Slot
    [Documentation]    Boot into the second SDV_B slot
    ${before}          Get Current RAUC Boot Name
    Should Match       ${before}    SDV_A
    ${next}            Get Next RAUC Boot Name
    Should Match       ${next}    SDV_A
    Set Next RAUC Boot Slot     rootfs.1
    ${next2}           Get Next RAUC Boot Name
    Should Match       ${next2}    SDV_B
    Leda Reboot
    ${after}           Get RAUC Boot Primary Slot
    Should Match       ${after}     rootfs.1
    ${next3}           Get Next RAUC Boot Name
    Should Match       ${next3}    SDV_B
