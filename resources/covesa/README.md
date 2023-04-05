# COVESA VSS Tools Docker Container

This docker container uses VSS `vspec2json.py` to convert a custom DBC and VSpec mapping to a full VSS-DBC mapping.

The mapping can then be used by Eclipse Kuksa.VAL Databroker and Kuksa.VAL Feeders (dbc2val) to feed actual CAN Frames into the VSS data model.

## Usage

1. Provide the custom `.dbc` file in the location `./data/custom.dbc`

    The example included is taken from https://github.com/eclipse/kuksa.val.feeders/tree/main/dbc2val

2. Provide a custom vspec mapping file in the location `./data/custom.vspec`

    This demo file maps two CAN signals from two different CAN messages into the respective VSS paths.

    Note: The vspec2json tool does not validate whether the signals are actually defined in the DBC!

3. Run the vspec2json container:

    docker run --rm -v ./data:/data ghcr.io/eclipse-leda/leda-distro/leda-vss-vspec2json

4. A new file `./data/custom_vss_dbc.json` is generated.


## Kuksa.VAL Databroker

Run the databroker:

    docker run \
        --name databroker \
        --detach \
        --rm \
        -p 55555:55555/tcp \
        ghcr.io/eclipse/kuksa.val/databroker:0.3.1

## Kuksa.VAL dbc2val feeder

Run (from sources):

    kuksa.val.feeders/dbc2val/dbcfeeder.py \
        --dumpfile candump.log \
        --canport vcan0 \
        --server-type kuksa_databroker \
        --dbcfile custom.dbc \
        --mapping custom_vss_dbc.json

Run (using Docker container):

    docker run --name dbc2val --rm --detach \
        -v `pwd`:/custom \
        --network host \
        --privileged \
        -e LOG_LEVEL=debug \
        ghcr.io/eclipse/kuksa.val.feeders/dbc2val \
        --canport vcan0 \
        --use-socketcan \
        --server-type kuksa_databroker \
        --dbcfile /custom/custom.dbc \
        --mapping /custom/custom_vss_dbc.json
