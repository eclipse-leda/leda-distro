#!/bin/bash
# Bash strict mode
set -euo pipefail
apt-get update
apt-get -y install --no-install-recommends wget
apt-get -y install --no-install-recommends containerd
command -v containerd

wget "https://github.com/eclipse-kanto/kanto/releases/download/v0.1.0-M3/kanto_0.1.0-M3_linux_x86_64.deb"
apt-get install -y ./kanto_0.1.0-M3_linux_x86_64.deb
command -v container-management
command -v kanto-cm

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-utils_0.0.2.0.00680_all.deb"
apt-get install -y ./eclipse-leda-utils_0.0.2.0.00680_all.deb

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-kantui_0.0.2.0.00680_amd64.deb"
apt-get install -y ./eclipse-leda-kantui_0.0.2.0.00680_amd64.deb

wget "https://github.com/eclipse-leda/leda-utils/releases/download/v0.0.2/eclipse-leda-kanto-auto-deployer_0.0.2.0.00680_amd64.deb"
apt-get install -y ./eclipse-leda-kanto-auto-deployer_0.0.2.0.00680_amd64.deb

wget "https://github.com/eclipse-leda/meta-leda/releases/download/0.1.0-M2/eclipse-leda-containers_0.1.0.2.0.422_all.deb"
apt-get install -y ./eclipse-leda-containers_0.1.0.2.0.422_all.deb
