# /********************************************************************************
# * Copyright (c) 2022 Contributors to the Eclipse Foundation
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

do_install:append() {
    sed -i -e 's,#listener,listener 1883,g' \
        -e 's,#protocol mqtt,protocol mqtt,g' \
        -e 's,#allow_anonymous false,allow_anonymous true,g' \
        ${D}${sysconfdir}/mosquitto/mosquitto.conf
}