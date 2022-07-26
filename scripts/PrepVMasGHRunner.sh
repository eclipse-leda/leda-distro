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

# admin user of VM should be called runner
# parameter used to make this VM a GH Runner for the yocto tool chain repo leda-distro
# call :  PrepVMasGHRunner.sh  "ASYVOMQB...E5DCY" 2
token=$1              # "ASYVOMQB...E5DCY"
GH_RUNNER_COUNTER=$2  # $((i+1))

url="https://github.com/eclipse-leda/leda-distro"
version="2.288.1"
org="eclipse-leda"

# Install Rust
curl https://sh.rustup.rs -sSf | sh -s -- -y

# prepend cargo/bin in PATH
source ~/.cargo/env


# Install Docker
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    sourcel \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


# Install the Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Docker Post Installation
# To be able to use docker without sudo:
sudo usermod -aG docker runner


# Install Cargo Cross
sudo apt-get install -y build-essential
cargo install cross --version 0.1.16
sudo apt-get install jq -y

# install further tools for bitbake
sudo apt-get -y install --no-install-recommends \
    socat file \
    gawk wget git diffstat unzip texinfo gcc build-essential chrpath socat cpio \
    python3 python3-pip python3-pexpect xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint3 xterm python3-subunit mesa-common-dev zstd liblz4-tool

# install skopeo
# needs ubunut 20.10 or newer:   sudo apt-get -y install skopeo
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key | sudo apt-key add -
sudo apt-get update
sudo apt-get -y install skopeo

# install scan code
# If python is not present - install it.
python3 --version
if [ "$?" -ne "0" ]; then
    echo "Will install python"
    sudo apt install -y python3
    sudo apt install -y python3-dev bzip2 xz-utils zlib1g libxml2-dev libxslt1-dev libpopt0
    sudo apt install -y python3-distutils
    python3 --version
fi

# If scancode is not present - install it.
SCANCODE_FILE=scancode-toolkit-30.1.0_py38-linux.tar.xz

cd ./scancode/scancode-toolkit-30.1.0 

./scancode --help
if [ "$?" -ne "0" ]; then
    mkdir scancode
    cd scancode
    curl -L "https://github.com/nexB/scancode-toolkit/releases/download/v30.1.0/$SCANCODE_FILE" --output "$SCANCODE_FILE"
    tar -xf "$SCANCODE_FILE"
    # Initial run to configure. Must be run from the installation dir.
    cd scancode-toolkit-30.1.0
    ./scancode --help
    rm "../$SCANCODE_FILE"
fi



# ---- make this VM a GH Runner ----------
dir=/home/runner/actions-runner-$GH_RUNNER_COUNTER
mkdir $dir && cd $dir
echo "Download and configure GitHub Runner $GH_RUNNER_COUNTER in $dir"
curl -o actions-runner-linux-x64-$version.tar.gz -L https://github.com/actions/runner/releases/download/v$version/actions-runner-linux-x64-$version.tar.gz
tar xzf ./actions-runner-linux-x64-$version.tar.gz
sudo chown -R runner:runner $dir
sudo -u runner ./config.sh --url $url --token $token --name sdv-gh-runner-$GH_RUNNER_COUNTER --unattended

# service name is in format "actions.runner.<org>.<repo>.<runner name>" and gets cut off if too long
# thus the number in runner name is cut off (resulting in all but the first deployed runner being offline)
# -> solution: Rename hardcoded systemd service name in generated shell script
sed -i -e "s/$org.*\.service/$org\.agent-$GH_RUNNER_COUNTER\.service/" ./svc.sh
sed -i -e "s/$org.*)/$org\.agent-$GH_RUNNER_COUNTER)/" ./svc.sh

echo "Start GitHub Runner $GH_RUNNER_COUNTER"
sudo ./svc.sh install
sudo ./svc.sh start

# add the path for cargo cross to the runner path
sed -i 's/^/\/home\/runner\/.cargo\/bin:/' .path

# provide a fresh started system
sudo reboot