:: Start Quickstart image using Qemu on Windows
:: 

@ECHO OFF 

SET Path=c:\Program Files\qemu;%Path%`
SET QEMU_BIN=qemu-system-aarch64

qemu-system-aarch64 -net nic -netdev user,id=net0,hostfwd=tcp::2222-:22 -drive if=none,id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,format=qcow2 -device virtio-scsi-pci,id=scsi -device scsi-hd,drive=hd -usb -device usb-tablet -serial mon:stdio -serial null -serial mon:vc -object can-bus,id=canbus0 -device kvaser_pci,canbus=canbus0 -cpu IvyBridge -machine q35 -smp 4 -m 4G -bios u-boot.bin

