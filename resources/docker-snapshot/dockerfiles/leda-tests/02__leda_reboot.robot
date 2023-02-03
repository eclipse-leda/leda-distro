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
    [Documentation]    Execute a reboot
    ${before}          Get RAUC Boot Primary
    Should Match       ${before}    rootfs.0
    Leda Reboot
    ${after}           Get RAUC Boot Primary
    Should Match       ${after}     rootfs.0
