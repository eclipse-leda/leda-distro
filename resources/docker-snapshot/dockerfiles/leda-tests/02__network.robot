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
Documentation     Networking ${leda.target}
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process
Library  String
Library  JSONLibrary

Test Timeout       2 minutes

*** Variables ***
${leda.target}                 local
${leda.target.hostname}        localhost
${leda.sshport}                2002
${leda.ethernet.interface}     eth0

*** Test Cases ***

NetworkCtl Status ${leda.ethernet.interface}
    ${result}=             Leda Execute OK        networkctl status ${leda.ethernet.interface} --json=pretty
    ${json}=               Evaluate               json.loads("""${result.stdout}""")
    
    # See misc/example-networkctl-status-ether.json

    
    ${ipv4addr}=           Get Value From Json    ${json}    $..Addresses[?(@.Family == 2)]     fail_on_empty=${True}
    Should Be Equal As Integers          ${ipv4addr[0]['Address'][0]}     192
    Should Be Equal As Integers          ${ipv4addr[0]['Address'][1]}     168
    Should Be Equal As Integers          ${ipv4addr[0]['Address'][2]}     7
    Should Be Equal As Integers          ${ipv4addr[0]['Address'][3]}     2

    ${network_type}=       Get Value From Json    ${json}    $..Type     fail_on_empty=${True}
    Should Match           ${network_type[0]}     ether

    ${admin_state}=        Get Value From Json    ${json}    $..AdministrativeState     fail_on_empty=${True}
    Should Match           ${admin_state[0]}      configured

    ${op_state}=           Get Value From Json    ${json}    $..OperationalState     fail_on_empty=${True}
    Should Match           ${op_state[0]}         routable

    ${addr_state}=         Get Value From Json    ${json}    $..AddressState     fail_on_empty=${True}
    Should Match           ${addr_state[0]}       routable

    ${online_state}=       Get Value From Json    ${json}    $..OnlineState     fail_on_empty=${True}
    Should Match           ${online_state[0]}     online

    ${required_online}=    Get Value From Json    ${json}    $..RequiredForOnline     fail_on_empty=${True}
    Should Be True         ${required_online[0]}    msg="ethernet interface should be required for online status"

    ${network_file}=       Get Value From Json    ${json}    $..NetworkFile     fail_on_empty=${True}
    Should Match           ${network_file[0]}     /lib/systemd/network/80-wired.network

    ${ip_addr_array}=      Get Value From Json    ${json}    $..OnlineState     fail_on_empty=${True}
    Should Match           ${online_state[0]}     online

NetworkCtl Status can0
    ${result}=             Leda Execute OK        networkctl status can0 --json=pretty
    ${json}=               Evaluate               json.loads("""${result.stdout}""")
    
    # See misc/example-networkctl-status-can0.json
    ${network_type}=       Get Value From Json    ${json}    $..Type     fail_on_empty=${True}
    Should Match           ${network_type[0]}     can

    ${admin_state}=        Get Value From Json    ${json}    $..AdministrativeState     fail_on_empty=${True}
    Should Match           ${admin_state[0]}      configured

    ${op_state}=           Get Value From Json    ${json}    $..OperationalState     fail_on_empty=${True}
    Should Match           ${op_state[0]}         carrier

    ${addr_state}=         Get Value From Json    ${json}    $..AddressState     fail_on_empty=${True}
    Should Match           ${addr_state[0]}       off

    ${online_state}=       Get Value From Json    ${json}    $..OnlineState     fail_on_empty=${True}
    Should Match           ${online_state[0]}     offline

    ${required_online}=    Get Value From Json    ${json}    $..RequiredForOnline     fail_on_empty=${True}
    # Should Not be True     ${required_online[0]}  msg="can0 network should not be required for online status"
    Should Be True         ${required_online[0]}

    ${network_file}=       Get Value From Json    ${json}    $..NetworkFile     fail_on_empty=${True}
    Should Match           ${network_file[0]}     /lib/systemd/network/can0.network

NetworkCtl Status kanto-cm0
    ${result}=             Leda Execute OK        networkctl status kanto-cm0 --json=pretty
    ${json}=               Evaluate               json.loads("""${result.stdout}""")
    
    # See misc/example-networkctl-status-kanto-cm0.json
    ${network_type}=       Get Value From Json    ${json}    $..Type     fail_on_empty=${True}
    Should Match           ${network_type[0]}     bridge

    # Kanto is managing this network interface, not networkctl.
    ${admin_state}=        Get Value From Json    ${json}    $..AdministrativeState     fail_on_empty=${True}
    Should Match           ${admin_state[0]}      unmanaged         msg=AdministrativeState

    ${op_state}=           Get Value From Json    ${json}    $..OperationalState     fail_on_empty=${True}
    Should Match           ${op_state[0]}         degraded-carrier  msg=OperationalState

    ${addr_state}=         Get Value From Json    ${json}    $..AddressState     fail_on_empty=${True}
    Should Match           ${addr_state[0]}       routable          msg=AddressState

Ping Gateway
    ${result}=             Leda Execute OK        ping -c 3 192.168.7.1

# Ping External
#    ${result}=             Leda Execute OK        ping -c 3 1.1.1.1

Ping Leda Bundle Server
    ${result}=             Leda Execute OK        ping -c 3 leda-bundle-server.leda-network

Ping Non-Existent Fails
    ${result}=             Leda Execute        ping -c 3 foo.bar
    Should Be Equal As Integers    ${result.rc}    1

DNS Lookup Leda Bundle Server
    ${result}=             Leda Execute OK        nslookup leda-bundle-server.leda-network

DNS Lookup External
    ${result}=             Leda Execute OK        nslookup www.eclipse.org

DNS Lookup For Non-Existent Fails
    ${result}=             Leda Execute           nslookup foo.bar
    Should Be Equal As Integers    ${result.rc}    1

Wget External
    ${result}=             Leda Execute OK          wget --spider https://eclipse.org
