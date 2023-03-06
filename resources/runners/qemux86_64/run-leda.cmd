:: Start Quickstart image using Qemu on Windows
:: 

@ECHO OFF 

SET Path=c:\Program Files\qemu;%Path%`
SET QEMU_BIN=qemu-system-x86_64

:: With "-drive ovmf.qcow2", qemu boots to UEFO Boot Shell
:: qemu-system-x86_64 -net nic -netdev user,id=net0,hostfwd=tcp::2222-:22 -drive if=none,id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,format=qcow2 -device virtio-scsi-pci,id=scsi -device scsi-hd,drive=hd -usb -device usb-tablet -serial mon:stdio -serial null -serial mon:vc -object can-bus,id=canbus0 -device kvaser_pci,canbus=canbus0 -drive if=pflash,format=qcow2,file=ovmf.qcow2 -cpu IvyBridge -machine q35 -smp 4 -m 4G

:: With "-bios ovmf.qcow2", qemu directly boots to grub.
qemu-system-x86_64 -net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::1880-:1880,hostfwd=tcp::1883-:1883,hostfwd=tcp::8888-:8888,hostfwd=tcp::30555-:30555 -device virtio-blk,drive=hd,bootindex=1 -drive if=none,id=hd,file=sdv-image-all-qemux86-64.wic.qcow2,format=qcow2 -usb -device usb-tablet -serial mon:stdio -object can-bus,id=canbus0 -device kvaser_pci,canbus=canbus0 -bios ovmf.qcow2 -cpu IvyBridge -machine q35 -smp 4 -m 4G
