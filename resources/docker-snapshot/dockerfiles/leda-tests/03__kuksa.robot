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
Documentation     Kuksa Databroker ${leda.target}
Resource          leda_keywords.resource

Library  OperatingSystem
Library  Process
Library  String

Test Timeout       2 minutes

*** Variables ***
${leda.target}           local
${kuksa_hostname}        localhost
${kuksa_port}            30555

&{datapoints_map}

*** Test Cases ***

Get Single Metadata
    [Documentation]      Retrieve metadata
    ${json}=           Kuksa Get Metadata
    ...                name=Vehicle.Powertrain.TractionBattery.CurrentVoltage
    Should Match       ${json['list'][0]['name']}        Vehicle.Powertrain.TractionBattery.CurrentVoltage
    Should Match       ${json['list'][0]['dataType']}    FLOAT
    Should Match       ${json['list'][0]['changeType']}  CONTINUOUS

Unavailable Value
    [Documentation]      Check for NOT_AVAILABLE
    ${datapoint}=      Set variable    Vehicle.Powertrain.TractionBattery.CurrentVoltage
    ${json}=           Kuksa Get Value
    ...                name=${datapoint}
    # ${json} = {'datapoints': {'Vehicle.Powertrain.TractionBattery.CurrentVoltage': {'timestamp': '2023-02-10T08:49:41.224895342Z', 'failureValue': 'NOT_AVAILABLE'}}}
    Should Match       ${json['failureValue']}    NOT_AVAILABLE

Register A Datapoint
    [Documentation]      Register "Foo" as float
    ${json}=           Kuksa Register Datapoint
    ...        name=Foo
    ...        datatype=FLOAT
    ...        description=Bar

Update A Datapoint
    [Documentation]      Set and retrieve a random value
    ${random}=                     Evaluate    random.random()
    ${updatecmd}=                  Kuksa Update Datapoint   name=Foo   value=${random}
    Should Be Empty                ${updatecmd}
    ${setvalue}=                   Kuksa Get Value    name=Foo
    Should Be Equal As Numbers     ${setvalue['floatValue']}    ${random}    precision=3
    Should Not Be Empty            ${setvalue['timestamp']}

# UNIMPLEMENTED IN KUKSA DATABROKER
# Kuksa Set A Value
#     ${datapoint}=      Set variable    Foo
#     ${json}=           Kuksa Set Value
#     ...                name=${datapoint}
#     ...                value=123.456
#     # ${json} = {'datapoints': {'Vehicle.Powertrain.TractionBattery.CurrentVoltage': {'timestamp': '2023-02-10T08:49:41.224895342Z', 'failureValue': 'NOT_AVAILABLE'}}}
#     Should Match       ${json['failureValue']}    NOT_AVAILABLE

Get All Metadata
    ${json}=    Kuksa Get All Metadata
    ${length}=     Get length          ${json['list']}
    Set Test Message    Found metadata for ${length} VSS datapoints
    IF  ${length} < 100
        FAIL    Did not receive at least 100 datapoints metadata from Kuksa Databroker
    END

*** Keywords ***
Kuksa Register Datapoint
    [Arguments]        ${name}  ${datatype}  ${description}  ${changetype}=CONTINUOUS
    ${json}=    Kuksa Invoke
    ...                service=sdv.databroker.v1.Collector
    ...                method=RegisterDatapoints
    ...                payload={"list": [ {"name": "${name}", "data_type":"${datatype}", "description":"${description}", "change_type":"${changetype}" } ]}
    ${datapoint_id}=    Set variable    ${json['results']['${name}']}
    Set To Dictionary    ${datapoints_map}      ${name}    ${datapoint_id}
    RETURN  ${json}

Kuksa Update Datapoint
    [Arguments]        ${name}  ${value}
    ${datapoint_id}=    Set variable    ${datapoints_map['${name}']}
    Log    ${datapoint_id}
    ${json}=    Kuksa Invoke
    ...                service=sdv.databroker.v1.Collector
    ...                method=UpdateDatapoints
    ...                payload={"datapoints": { "${datapoint_id}": { "float_value" : ${value} }} }
    RETURN  ${json}

Kuksa Get Value
    [Documentation]    Get value of a VSS data point
    [Arguments]        ${name}
    ${json}=    Kuksa Invoke
    ...                service=sdv.databroker.v1.Broker
    ...                method=GetDatapoints
    ...                payload={"datapoints": ["${name}"]}
    RETURN  ${json['datapoints']['${name}']}

Kuksa Set Value
    [Documentation]    Get value of a VSS data point
    [Arguments]        ${name}  ${value}
    ${json}=    Kuksa Invoke
    ...                service=sdv.databroker.v1.Broker
    ...                method=SetDatapoints
    ...                payload={"datapoints": { "${name}" : { "float_value" : ${value} } } }
    RETURN  ${json}

Kuksa Get All Metadata
    [Documentation]    Get metadata for all VSS datapoints
    ${json}=    Kuksa Invoke Without Payload
    ...                service=sdv.databroker.v1.Broker
    ...                method=GetMetadata
    RETURN  ${json}

Kuksa Get Metadata
    [Documentation]    Get metadata for single VSS Entry
    [Arguments]        ${name}
    ${json}=    Kuksa Invoke
    ...                service=sdv.databroker.v1.Broker
    ...                method=GetMetadata
    ...                payload={"names": ["${name}"]}
    RETURN  ${json}

Kuksa Invoke
    [Documentation]    Call a Kuksa DataBroker service operation
    [Arguments]        ${service}  ${method}  ${payload}
    ${expanded}=       Format String    {import} {proto} -d @ -plaintext {address} {grpc_service}
    ...    import=-import-path ./kuksa.val/kuksa_databroker/proto
    ...    proto=-proto sdv/databroker/v1/broker.proto -proto sdv/databroker/v1/collector.proto
    ...    address=${kuksa_hostname}:${kuksa_port}
    ...    grpc_service=${service}/${method}
    Log Variables
    ${result}=    Run Process    grpcurl ${expanded}
    ...    stdin=${payload}
    ...    shell=True
    Log    ${result.rc}
    Log    ${result.stdout}
    Log    ${result.stderr}
    Should Be Empty 	${result.stderr}    msg=grpc call returned: ${result.stderr}
    ${json}=    Evaluate    json.loads("""${result.stdout}""")
    Log    ${json}
    RETURN    ${json}

Kuksa Invoke Without Payload
    [Documentation]    Call a Kuksa DataBroker service operation without a request body payload
    [Arguments]        ${service}  ${method}
    ${expanded}=       Format String    {import} {proto} -plaintext {address} {grpc_service}
    ...    import=-import-path ./kuksa.val/kuksa_databroker/proto
    ...    proto=-proto sdv/databroker/v1/broker.proto -proto sdv/databroker/v1/collector.proto
    ...    address=${kuksa_hostname}:${kuksa_port}
    ...    grpc_service=${service}/${method}
    ${result}=    Run Process    timeout 1s grpcurl ${expanded}
    ...    shell=True
    ...    stdout=${TEMPDIR}${/}stdout.txt
    Should Be Empty 	${result.stderr}    msg=grpc call returned: ${result.stderr}
    ${file}=    Get File    ${TEMPDIR}${/}stdout.txt
    Remove File    ${TEMPDIR}${/}stdout.txt
    ${json}=    Evaluate    json.loads("""${file}""")
    RETURN    ${json}
