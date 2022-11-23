#!/bin/bash
#
# Setup virtual CAN bus interface
#
# sudo modprobe vcan
# sudo ip link add dev vcan0 type vcan
# sudo ip link set up vcan0

 
# Start replay
#
canplayer \
    -l 'i' \
    -I SOC_Manual_candump-2022-04-06_125818.log \
    -v \
    vcan0=can0
