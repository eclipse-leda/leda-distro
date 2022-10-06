#!/bin/bash

function askInstall() {
    local PACKAGE=$1
    while true
    do
        echo "The following package are required, but missing: $PACKAGE"
        echo "Do you wish to install $PACKAGE using sudo?"
        select ync in "Yes" "No" "Cancel"; do
            case $ync in
                Yes )
                    sudo apt-get install -y $PACKAGE;
                    return 1
                ;;
                No )
                    return 0
                ;;
                Cancel )
                    exit
                ;;
            esac
        done
    done
}

function checkInstall() {
    local CMD=$1
    local PACKAGE=$2
    if ! command -v $1 &> /dev/null
    then
        askInstall "$PACKAGE"
    else
        echo "$CMD found."
    fi
}

checkInstall "qemu-system-arm" "qemu-system-arm"
checkInstall "tunctl" "uml-utilities bridge-utils"

CMD_TUNCTL=$(which tunctl)
CMD_IFCONFIG=$(which ip)
CMD_IPTABLES=$(which iptables)

USER_USERID=$(id -u)
USER_GROUPID=$(id -g)

TAP=`sudo $CMD_TUNCTL -b -u $USER_USERID -g $USER_GROUPID 2>&1`

function tap_setup {
    echo "Setting up TAP network interface $TAP"
    sudo $CMD_IFCONFIG addr add 192.168.7.2/32 broadcast 192.168.7.255 dev $TAP
    sudo $CMD_IFCONFIG link set dev $TAP up
    sudo $CMD_IFCONFIG route add to 192.168.7.1 dev $TAP
    sudo $CMD_IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.1/32
    sudo $CMD_IPTABLES -A POSTROUTING -t nat -j MASQUERADE -s 192.168.7.2/32
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
    sudo bash -c "echo 1 > /proc/sys/net/ipv4/conf/$TAP/proxy_arp"
    sudo $CMD_IPTABLES -P FORWARD ACCEPT
}

# deletes the temp directory
function tap_cleanup {      
    echo "Removing TAP network interface $TAP"
    sudo $CMD_TUNCTL -d $TAP
    sudo $CMD_IFCONFIG link del $TAP
    sudo $CMD_IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$n/32
    sudo $CMD_IPTABLES -D POSTROUTING -t nat -j MASQUERADE -s 192.168.7.$dest/32

}

# register the cleanup function to be called on the EXIT signal
trap tap_cleanup EXIT

# Set up network interface for QEMU
tap_setup

echo "Running QEMU"
sudo qemu-system-arm \
    -device e1000,netdev=net0,mac=52:54:00:12:34:03 \
    -netdev tap,id=net0,ifname=$TAP,script=no,downscript=no \
    -object rng-random,filename=/dev/urandom,id=rng0 \
    -device virtio-rng-pci,rng=rng0 \
    -drive id=disk0,file=sdv-image-all-qemuarm.wic.qcow2,if=none,format=qcow2 \
    -device virtio-blk-device,drive=disk0 \
    -device qemu-xhci \
#    -serial mon:stdio \
    -serial null -nographic \
    -object can-bus,id=canbus0  \
    -device kvaser_pci,canbus=canbus0  \
    -machine virt,highmem=off \
    -cpu cortex-a15 -smp 4 -m 2048 -serial mon:vc \
    -device virtio-gpu-pci \
    -kernel ./zImage-qemuarm.bin \
    -append 'root=/dev/vda4 rw ip=192.168.7.2::192.168.7.1:255.255.255.0'
