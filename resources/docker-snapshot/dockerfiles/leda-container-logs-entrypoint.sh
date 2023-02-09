#!/bin/sh

mkdir -p ~/.ssh/

ssh-keyscan -p 2222 -H leda-x86.leda-network >> ~/.ssh/known_hosts 2> /dev/null
ssh -p 2222 root@leda-x86.leda-network mkdir -p /data/var/opentelemetry
scp -P 2222 ./config.yaml root@leda-x86.leda-network:/data/var/opentelemetry
scp -P 2222 ./otel-collector.json root@leda-x86.leda-network:/data/var/containers/manifests_dev
ssh -p 2222 root@leda-x86.leda-network kanto-cm stop --force --name otelcollector
ssh -p 2222 root@leda-x86.leda-network kanto-cm remove --force --name otelcollector
ssh -p 2222 root@leda-x86.leda-network kanto-auto-deployer /data/var/containers/manifests_dev

bash

/data/var/opentelemetry/config.yaml