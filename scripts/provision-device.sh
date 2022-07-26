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

BACKTITLE="Eclipse Leda Device Provisioning"
TITLE="Azure Subscription"
HEIGHT=15
WIDTH=40
CHOICE_HEIGHT=4

(>&2 cat < /dev/null > /dev/tcp/localhost/2222) > /dev/null 2>&1
RC_NETWORK_CHECK_SLIRP=$?
(>&2 cat < /dev/null > /dev/tcp/192.168.7.2/22) > /dev/null 2>&1
RC_NETWORK_CHECK_TAP=$?

dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Detect QEMU networking mode ..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

#echo "Slirp: ${RC_NETWORK_CHECK_SLIRP}"
#echo "TAP: ${RC_NETWORK_CHECK_TAP}"

if [ ${RC_NETWORK_CHECK_TAP} ];
then
    SSH_CONNECT_OPTS="-q -o StrictHostKeyChecking=off -p 22 root@192.168.7.2"
    ssh-keygen -f ~/.ssh/known_hosts -R "192.168.7.2:22" > /dev/null 2>&1
else 
    SSH_CONNECT_OPTS="-q -o StrictHostKeyChecking=off -p 2222 root@localhost"
    ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2222" > /dev/null 2>&1
fi 

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
fi

if ! az account get-access-token &> /dev/null
then
    askAzureLogin
    askAzureSubscription
fi

dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Getting list of Azure IoT Hubs..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

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

dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Getting list of Azure IoT Devices..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

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
    az iot hub device-identity create -n ${IOT_HUB} -d ${DEVICE_ID}
fi 

if [ -z $DEVICE_ID ]
then 
    exit 
fi

dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Getting device credentials..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

CONNSTRING=$(az iot hub device-identity connection-string show -n ${IOT_HUB} -d ${DEVICE_ID} -o tsv)
echo "$CONNSTRING" > connection-string.${DEVICE_ID}.txt

# waiting for k3s to be started 
while true ; do
  isRunning="false"
  status=$(ssh ${SSH_CONNECT_OPTS} systemctl is-active k3s) 
  for i in ${status[@]} ; do
    if [[ "$i" == "active" ]]; then
      isRunning="true"
      break
    fi
  done 

  if [[ "$isRunning" == "true" ]]; then
    dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Kubernetes is ready..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty
    break
  else
    dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Waiting for Kubernetes to become ready..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty
    sleep 5
  fi
done

ssh ${SSH_CONNECT_OPTS} /usr/local/bin/kubectl version

#
# Configure Connection String Secret
#
dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Creating Kubernetes Secret for Cloud Connector..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

ssh ${SSH_CONNECT_OPTS} /usr/local/bin/kubectl delete secret cloudagent

CMD="/usr/local/bin/kubectl create secret generic cloudagent --from-literal=PrimaryConnectionString=\"$CONNSTRING\""
ssh ${SSH_CONNECT_OPTS} $CMD

EXISTING_GHCR_IO=$(ssh ${SSH_CONNECT_OPTS} /usr/local/bin/kubectl get secret ghcr-io)
RC=$?

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

dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Creating Kubernetes Secret for GHCR.IO Container Registry..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

        # delete existing secret if its exist
        secrets=$(ssh ${SSH_CONNECT_OPTS} /usr/local/bin/kubectl get secrets | awk '{print $1}') 
        for secret in ${secrets[@]} ; do
            if [[ "$secret" == "ghcr-io" ]]; then
                ssh ${SSH_CONNECT_OPTS} "/usr/local/bin/kubectl delete secret ghcr-io > /dev/null" > /dev/null
                break
            fi
        done 
        ssh ${SSH_CONNECT_OPTS} "/usr/local/bin/kubectl create secret docker-registry ghcr-io \
            --docker-server=ghcr.io \
            --docker-username=\"$GHCR_USERNAME\" \
            --docker-password=\"$GHCR_PAT\" > /dev/null"  > /dev/null
    fi

fi

#ssh ${SSH_CONNECT_OPTS} /usr/local/bin/kubectl logs sdv-core-cloud-agent-pod


dialog  \
    --backtitle "$BACKTITLE" \
    --title "$TITLE" \
    --no-items \
    --infobox "Getting SDV Status Health ..." \
    $HEIGHT $WIDTH \
    2>&1 >/dev/tty

dialog --clear

echo "Getting SDV Health Status ..."
ssh ${SSH_CONNECT_OPTS} /bin/bash -l -c /usr/bin/sdv-health

echo ""
echo "You can now login to the device:"
echo "    ssh ${SSH_CONNECT_OPTS}"