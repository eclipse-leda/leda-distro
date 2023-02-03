#!/bin/bash

function askInstallQemu() {
    while true
    do
        echo "Do you wish to install qemu-system-arm using sudo?"
        select ync in "Yes" "No" "Cancel"; do
            case $ync in
                Yes )
                    sudo apt install qemu-system-arm;
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

if ! command -v qemu-system-aarch64 --version &> /dev/null
then
    echo "Qemu not installed."
    askInstallQemu
else
    echo "Qemu found."
fi

qemu-system-aarch64 \
         -kernel ./Image-qemuarm64.bin \
         -m 4G \
         -machine virt -cpu cortex-a57 \
         -nographic \
         -drive if=none,file=sdv-image-all-qemuarm64.wic.qcow2,format=qcow2,id=hd \
         -device virtio-blk-device,drive=hd \
         -netdev user,id=net0,hostfwd=tcp::2222-:22 \
         -device virtio-net-device,netdev=net0 \
         -object can-bus,id=canbus0 \
         -device kvaser_pci,canbus=canbus0 \
         -bios u-boot.bin
