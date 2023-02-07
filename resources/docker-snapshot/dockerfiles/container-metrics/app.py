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
#

from flask import Flask, make_response, redirect
from flask_mqtt import Mqtt
import json 
import re
import logging

appname = "kanto2prometheus"

logging.basicConfig(encoding='utf-8', level=logging.INFO, format='%(asctime)s %(message)s')
flask_logger = logging.getLogger('werkzeug')
flask_logger.setLevel(logging.ERROR)

log = logging.getLogger(appname)
log.setLevel(logging.INFO)
app = Flask(appname)

#app.config['MQTT_BROKER_URL'] = 'leda-mqtt-broker.leda-network'
app.config['MQTT_BROKER_URL'] = 'localhost'
app.config['MQTT_BROKER_PORT'] = 1883
app.config['MQTT_USERNAME'] = ''
app.config['MQTT_PASSWORD'] = ''
app.config['MQTT_KEEPALIVE'] = 5
app.config['MQTT_TLS_ENABLED'] = False

topic = '+/e/dummy-tenant-id/dummy-namespace:dummy-gateway:dummy-device-id:edge:containers'

prometheus_metric_prefix = "leda_container"

# Initialize empty dictionaries
prometheus_metrics = {}
containerNames = {}

mqtt_client = Mqtt(app=app, connect_async=True)

@mqtt_client.on_connect()
def on_connect(client, userdata, flags, rc):
    log.info('Subscribing to MQTT topic: %s',topic)
    mqtt_client.subscribe(topic)

@mqtt_client.on_subscribe()
def on_subscribe(client, userdata, mid, granted_qos):
    log.info('Subscribed')

@mqtt_client.on_unsubscribe()
def on_unsubscribe(client, userdata, mid):
    log.info('Subscribing to MQTT topic: %s',topic)
    mqtt_client.subscribe(topic)
    
@mqtt_client.on_disconnect()
def on_disconnect():
    log.warning('Disconnected from MQTT')

def parseContainerState(topic,data):
    # data[path] = /features/Container:95aaa60b-4b1f-40f5-b7c6-8fb4a51510c8/properties/status/state
    # print("parsing",data)
    
    if "com.bosch.iot.suite.edge.containers:Container:1.5.0" in data['value']['definition']:
        splitted = data['path'].split('/')
        container_with_prefix=splitted[2]
        splitted2 = container_with_prefix.split(":")
        containerId=splitted2[1]
        containerName=data['value']['properties']['status']['name']
        containerNames[containerId]=containerName
        log.info("Received container name: %s = %s", containerId, containerName)
    elif "com.bosch.iot.suite.edge.containers:ContainerFactory:1.3.0" in data['value']['definition']:
        # Skippable
        return
    else:
        log.warning("Ignoring unknown container message: %s",data['value']['definition'])

def parseMetrics(topic,data):
    tenantId=topic.split("/")[2]
    # "topic": "dummy-namespace/dummy-gateway:dummy-device-id:edge:containers/things/live/messages/data",
    topic_split = data['topic'].split('/')
    # dummy-namespace
    topic_namespace = topic_split[0]
    # dummy-gateway:dummy-device-id:edge:containers
    topic_full_device_identifier = topic_split[1]
    deviceIds=topic_full_device_identifier.split(":")
    deviceId=deviceIds[0] + ":" + deviceIds[1]
    
    snapshots = data['value']['snapshot']
    for snapshot in snapshots:
            originator = snapshot['originator']
            measurements = snapshot['measurements']
            for measurement in measurements:
                mId = measurement['id']
                mValue = measurement['value']
                prom_metric_name = re.sub(r'[^\x00-\x7F]', '_', mId).lower()
                prom_metric_name = re.sub(r'[\.]', '_', prom_metric_name).lower()
                prom_originator = re.sub(r'[^\x00-\x7F]', '_', originator).lower()
                prom_originator = re.sub(r'[:-]', '_', prom_originator).lower()
                
                containerId=originator.split(':')[1]
                
                if containerId in containerNames:
                    containerName=containerNames[containerId]
                else:
                    containerName=containerId
    
                prom_label = "containerId=\"{}\", tenantId=\"{}\", deviceId=\"{}\", name=\"{}\"".format(containerId,tenantId,deviceId,containerName)
                fullname = "{}_{}{{{}}}".format(prometheus_metric_prefix,prom_metric_name,prom_label)
                
                prometheus_metrics[fullname]=mValue

@mqtt_client.on_message()
def on_message(client, userdata, message):
    topic=message.topic
    payload=message.payload.decode()
    data = json.loads(payload)
    
    if (data['path'] == "/features/Metrics/outbox/messages/data"):
        log.info("Received Kanto container metrics update via MQTT")
        parseMetrics(topic,data)
        return
    
    if (data['path'].startswith("/features/Container")):
        # /features/Container:95aaa60b-4b1f-40f5-b7c6-8fb4a51510c8/properties/status/state
        parseContainerState(topic,data)
        return
    
    if (data['path'] == "/features/Metrics"):
        # Skippable
        return
    
    if (data['path'] == "/features/SoftwareUpdatable"):
        # Skippable
        return
    
    log.warning("Received Kanto message with unknown path: ",str(data['path']))

@mqtt_client.on_log()
def handle_logging(client, userdata, level, buf):
    if level == MQTT_LOG_ERR:
        log.error('Error: {}'.format(buf))

def generateMetrics():
    converted = str()
    for key in prometheus_metrics:
        converted += key + " " + str(prometheus_metrics[key]) + "\n"
    return converted

@app.route('/metrics')
def metrics():
    response = make_response(generateMetrics(), 200)
    response.mimetype = "text/plain"
    return response

@app.route('/')
def hello_world():
    return redirect("/metrics", code=302)

if __name__ == '__main__':
    log.info("Convert kanto container metrics messages and publish them as prometheus metrics")
    log.info("Startup of MQTT Client")
    mqtt_client.init_app(app)
    log.info("Startup of Flask web app")
    app.run(debug=False,port=7355)
