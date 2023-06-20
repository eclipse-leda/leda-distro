#!/bin/bash

mosquitto &

strace -s 1600 -f \
     -e trace=open,read,write \
     -o strace.log \
     container-management --ccl-ap /var/run/docker/containerd/containerd.sock &

sleep 2

until [ -S /var/run/container-management/container-management.sock ]
do
     echo "Waiting for Eclipse Kanto Container Management..."
     sleep 1
done

ctr --address=/var/run/docker/containerd/containerd.sock --namespace=kanto-cm snapshots rm databroker-snapshot
ctr --address=/var/run/docker/containerd/containerd.sock --namespace=kanto-cm snapshots rm cloudconnector-snapshot
ctr --address=/var/run/docker/containerd/containerd.sock --namespace=kanto-cm snapshots rm vum-snapshot
ctr --address=/var/run/docker/containerd/containerd.sock --namespace=kanto-cm snapshots rm cua-snapshot
ctr --address=/var/run/docker/containerd/containerd.sock --namespace=kanto-cm snapshots rm sua-snapshot

kanto-auto-deployer /var/containers/manifests/

kanto-cm list

bash

