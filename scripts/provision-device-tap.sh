#/bin/bash
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
#
# Perform an automated Device Provisioning
#
#set -x

BACKTITLE="SDV.EDGE Device Provisioning"
TITLE="Azure Subscription"
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4


function askInstallAzureCLI() {
    MENU="Choose one of the following options:"
    OPTIONS=(1 "Install Azure IoT CLI"
            2 "Skip")
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)
    case $CHOICE in
            1)
                echo "You chose Option 1"
                curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                az config set extension.use_dynamic_install=yes_without_prompt
                ;;
    esac
}

function askAzureLogin() {
    MENU="Choose one of the following options:"
    OPTIONS=(1 "Login to Azure"
            2 "Skip")
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONS[@]}" \
                    2>&1 >/dev/tty)
    case $CHOICE in
            1)
                echo "You chose Option 1"
                az login
                az config set extension.use_dynamic_install=yes_without_prompt
                ;;
    esac
}

function askAzureSubscription() {
    MENU="Choose the Azure Subscription:"
    OPTIONSS=($(az account list | jq ".[].name" | sed -e 's/\"//g'))
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --no-items \
                    --menu "$MENU" \
                    $HEIGHT $WIDTH $CHOICE_HEIGHT \
                    "${OPTIONSS[@]}" \
                    2>&1 >/dev/tty)
    az account set --subscription "$CHOICE"
}

if ! command -v az version &> /dev/null
then
    askInstallAzureCLI
else
    echo "Azure CLI already found."
fi

if ! az account get-access-token &> /dev/null
then
    askAzureLogin
    askAzureSubscription
else 
    echo "Azure CLI already authenticated."
fi

echo "Getting list of Azure IoT Hubs..."
MENU="Choose the Azure IoT Hub:"
OPTIONSH=($(az iot hub list | jq ".[].name" | sed -e 's/\"//g' | sort))
CHOICE=$(dialog  \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --no-items \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONSH[@]}" \
                2>&1 >/dev/tty)
IOT_HUB=$CHOICE

if [ -z $IOT_HUB ]
then 
    exit 
fi


echo "Getting list of Azure IoT Devices..."
OPTIONSD=($(az iot hub device-identity list -n $IOT_HUB | jq ".[].deviceId" | sed -e 's/\"//g' | sort))
if [ -z $OPTIONSD ]
then
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --no-items \
                    --inputbox "Please enter IOT device name" \
                    $HEIGHT $WIDTH \
                    2>&1 >/dev/tty)
    DEVICE_ID=$CHOICE
    az iot hub device-identity create -n ${IOT_HUB} -d ${DEVICE_ID}
else
    CHOICE=$(dialog  \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --no-items \
                --menu "$MENU" \
                $HEIGHT $WIDTH $CHOICE_HEIGHT \
                "${OPTIONSD[@]}" \
                2>&1 >/dev/tty)
fi

DEVICE_ID=$CHOICE

if [ -z $DEVICE_ID ]
then
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --no-items \
                    --inputbox "Please enter Device ID for new device" \
                    $HEIGHT $WIDTH \
                    2>&1 >/dev/tty)
    DEVICE_ID=$CHOICE
    az iot hub device-identity create -n ${IOT_HUB} -d ${DEVICE_ID} --ee
fi 

if [ -z $DEVICE_ID ]
then 
    exit 
fi

CONNSTRING=$(az iot hub device-identity connection-string show -n ${IOT_HUB} -d ${DEVICE_ID} -o tsv)
echo "$CONNSTRING" > connection-string.${DEVICE_ID}.txt

# Clean up previous SSH Fingerprints
echo "Pruning and Updating SSH Key Fingerprint for virtual device"
ssh-keygen -f "/home/vscode/.ssh/known_hosts" -R "192.168.7.2"

ssh -o "StrictHostKeyChecking=accept-new" root@192.168.7.2 /usr/local/bin/kubectl version

#
# Configure Connection String Secret
#
echo "Creating Kubernetes Secret for Cloud Connector..."
ssh root@192.168.7.2 /usr/local/bin/kubectl delete secret cloudagent

CMD="/usr/local/bin/kubectl create secret generic cloudagent --from-literal=PrimaryConnectionString=\"$CONNSTRING\""
ssh root@192.168.7.2 $CMD

EXISTING_GHCR_IO=$(ssh root@192.168.7.2 /usr/local/bin/kubectl get secret ghcr-io)
RC=$?

echo $RC
echo $EXISTING_GHCR_IO

CHOICE=$(dialog  \
                --backtitle "$BACKTITLE" \
                --title "$TITLE" \
                --no-items \
                --inputbox "Please enter username to access ghcr.io" \
                $HEIGHT $WIDTH \
                2>&1 >/dev/tty)
GHCR_USERNAME=$CHOICE

if [ ! -z $GHCR_USERNAME ]
then 
    
    CHOICE=$(dialog  \
                    --backtitle "$BACKTITLE" \
                    --title "$TITLE" \
                    --no-items \
                    --inputbox "Please enter personal access token to access ghcr.io" \
                    $HEIGHT $WIDTH \
                    2>&1 >/dev/tty)
    GHCR_PAT=$CHOICE

    if [ ! -z $GHCR_PAT ]
    then     
        #
        # Configure Container Registry Secret
        #
        echo "Creating Kubernetes Secret for GHCR.IO Container Registry..."

        # delete existing secret if its exist
        secrets=$(ssh root@192.168.7.2 /usr/local/bin/kubectl get secrets | awk '{print $1}') 
        for secret in ${secrets[@]} ; do
            echo $secret
            if [[ "$secret" == "ghcr-io" ]]; then
                ssh root@192.168.7.2 /usr/local/bin/kubectl delete secret ghcr-io
                break
            fi
        done 
        ssh root@192.168.7.2 /usr/local/bin/kubectl create secret docker-registry ghcr-io \
            --docker-server=ghcr.io \
            --docker-username="$GHCR_USERNAME" \
            --docker-password="$GHCR_PAT"
    fi

fi

echo "Getting logs of Cloud Connector ..."
ssh root@192.168.7.2 /usr/local/bin/kubectl logs sdv-core-cloud-agent-pod

echo "Finished."