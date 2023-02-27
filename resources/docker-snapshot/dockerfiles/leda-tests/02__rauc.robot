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
Documentation     RAUC on ${leda.target}
...               White box tests of the RAUC Update Bundle and its configuration details

Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process
Library  String
Library  JSONLibrary

Test Timeout       2 minutes

*** Variables ***
${leda.target}                  local
${leda.target.hostname}         localhost
${leda.sshport}                 2001
${rauc.update.bundle.filename}  sdv-rauc-bundle-qemux86-64.raucb

*** Test Cases ***

Check RAUC Status
    [Documentation]        Current booted partition
    ${result}=             Leda Execute   rauc status --output-format=json
    Should Be Equal As Integers 	${result.rc} 	${0}
    Should Be Empty    ${result.stderr}
    Should Not Be Empty    ${result.stdout}

    ${json}=               Evaluate    json.loads("""${result.stdout}""")
    ${rauc_booted_slot}=   Set variable  ${json['booted']}
    ${rauc_compatible}=    Set variable  ${json['compatible']}
    ${rauc_boot_primary}=  Set variable  ${json['boot_primary']}
    Set Test Message       Boot primary is ${rauc_boot_primary}
    Should Match 	${rauc_booted_slot} 	SDV_A
    Should Match 	${rauc_compatible} 	    Eclipse Leda
    Should Match 	${rauc_boot_primary} 	rootfs.0

    ${booted_json}=    Get Value From Json    ${json}    $..slots[*][?(@.state=='booted' & @.class=='rootfs')]       fail_on_empty=${True}
    ${installed_json}=  Get Value From Json    ${json}    $..slots[*][?(@.state=='inactive' & @.class=='rootfs')]     fail_on_empty=${True}

    Should Match 	${booted_json[0]['bootname']}         SDV_A
    Should Match 	${booted_json[0]['boot_status']}      good
    Should Match 	${booted_json[0]['class']}            rootfs
    Should Match 	${booted_json[0]['type']}             ext4

    Should Match 	${installed_json[0]['bootname']}      SDV_B
    Should Match 	${installed_json[0]['boot_status']}   good
    Should Match 	${installed_json[0]['class']}         rootfs
    Should Match 	${installed_json[0]['type']}          ext4

    # Example json data returned from Get Value From Json:
    # [
    #   {
    #     "class": "rootfs",
    #     "device": "/dev/vda5",
    #     "type": "ext4",
    #     "bootname": "SDV_B",
    #     "state": "booted",
    #     "parent": null,
    #     "mountpoint": "/",
    #     "boot_status": "bad",
    #     "slot_status": {
    #       "bundle": {
    #         "compatible": null
    #       }
    #     }
    #   }
    # ]

Direct RAUC Install
    [Documentation]        Install bundle and check details
    ${result_rm}=          Leda Execute         rm /data/${rauc.update.bundle.filename}
    ${result_curl}=        Leda Execute OK      wget -O /data/${rauc.update.bundle.filename} http://leda-bundle-server.leda-network/${rauc.update.bundle.filename}
    ${result_info}=        Leda Execute OK      rauc info --output-format=json /data/${rauc.update.bundle.filename}
    ${result_install}=     Leda Execute OK      rauc install /data/${rauc.update.bundle.filename}

    ${result_status}=      Leda Execute OK      rauc status --detailed --output-format=json
    ${json}=               Evaluate             json.loads("""${result_status.stdout}""")

    ${installed_json}=     Get Value From Json    ${json}    $..slots[*][?(@.slot_status.status=='ok')]     fail_on_empty=${True}
    
    Should Match 	${installed_json[0]['class']}            rootfs
    Should Match 	${installed_json[0]['device']}           /dev/vda5
    Should Match 	${installed_json[0]['type']}             ext4
    Should Match 	${installed_json[0]['bootname']}         SDV_B
    Should Match 	${installed_json[0]['state']}            inactive
    Should Match 	${installed_json[0]['boot_status']}      good

    Should Match                         ${installed_json[0]['slot_status']['bundle']['compatible']}       Eclipse Leda (*)
    Should Not be Empty                  ${installed_json[0]['slot_status']['bundle']['version']}
    Should Not Be Empty                  ${installed_json[0]['slot_status']['bundle']['build']}
    Should Match                         ${installed_json[0]['slot_status']['bundle']['description']}      sdv-rauc-bundle version 1.0-r0

    Should Not Be Empty                  ${installed_json[0]['slot_status']['checksum']['sha256']}
    Should Be True                       ${installed_json[0]['slot_status']['checksum']['size']}           > 100000000
    
    Should Be True                       ${installed_json[0]['slot_status']['installed']['count']}         >= 1
    Should Not Be Empty                  ${installed_json[0]['slot_status']['installed']['timestamp']}

    Should Be True                       ${installed_json[0]['slot_status']['activated']['count']}         >= 1
    Should Not Be Empty                  ${installed_json[0]['slot_status']['activated']['timestamp']}

    # Example output of "rauc status --output-format=json --detailed" after installation of the RAUC Bundle:
    # {
    #     "compatible": "Eclipse Leda",
    #     "variant": "",
    #     "booted": "SDV_A",
    #     "boot_primary": "rootfs.1",
    #     "slots": [
    #         {
    #             "rootfs.1": {
    #                 "class": "rootfs",
    #                 "device": "/dev/vda5",
    #                 "type": "ext4",
    #                 "bootname": "SDV_B",
    #                 "state": "inactive",
    #                 "parent": null,
    #                 "mountpoint": null,
    #                 "boot_status": "good",
    #                 "slot_status": {
    #                     "bundle": {
    #                         "compatible": "Eclipse Leda",
    #                         "version": "${VERSION_ID}",
    #                         "description": "sdv-rauc-bundle version 1.0-r0",
    #                         "build": "20230216133252"
    #                     },
    #                     "checksum": {
    #                         "sha256": "5eafc90d4ea9eb9f36bffcc5e1cb983c5326a461d6e73f6f02a1c663c0ebcbb6",
    #                         "size": 487356416
    #                     },
    #                     "installed": {
    #                         "timestamp": "2023-02-16T15:39:26Z",
    #                         "count": 3
    #                     },
    #                     "activated": {
    #                         "timestamp": "2023-02-16T15:39:26Z",
    #                         "count": 3
    #                     },
    #                     "status": "ok"
    #                 }
    #             }
    #         },
    #         {
    #             "efi.0": {
    #                 "class": "efi",
    #                 "device": "/dev/vda",
    #                 "type": "boot-gpt-switch",
    #                 "bootname": null,
    #                 "state": "inactive",
    #                 "parent": null,
    #                 "mountpoint": null,
    #                 "boot_status": null,
    #                 "slot_status": {
    #                     "bundle": {
    #                         "compatible": null
    #                     }
    #                 }
    #             }
    #         },
    #         {
    #             "rescue.0": {
    #                 "class": "rescue",
    #                 "device": "/dev/vda3",
    #                 "type": "ext4",
    #                 "bootname": null,
    #                 "state": "inactive",
    #                 "parent": null,
    #                 "mountpoint": null,
    #                 "boot_status": null,
    #                 "slot_status": {
    #                     "bundle": {
    #                         "compatible": null
    #                     }
    #                 }
    #             }
    #         },
    #         {
    #             "rootfs.0": {
    #                 "class": "rootfs",
    #                 "device": "/dev/vda4",
    #                 "type": "ext4",
    #                 "bootname": "SDV_A",
    #                 "state": "booted",
    #                 "parent": null,
    #                 "mountpoint": "/",
    #                 "boot_status": "good",
    #                 "slot_status": {
    #                     "bundle": {
    #                         "compatible": null
    #                     }
    #                 }
    #             }
    #         }
    #     ]
    # }
