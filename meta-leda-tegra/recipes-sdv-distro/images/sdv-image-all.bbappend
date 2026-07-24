# Tegra needs a plain WIC file (not qcow2) to be flashed to SD-Card
WKS_FILE:jetson-nano-2gb-devkit ?= "jetson-nano-2gb-devkit.wks"
IMAGE_FSTYPES:jetson-nano-2gb-devkit = "tegraflash tar.gz wic.gz"

IMAGE_BOOT_FILES:jetson-nano-2gb-devkit = "Image u-boot.bin tegra210-p3448-0003-p3542-0000-jetson-nano-2gb-devkit.dtb u-boot-jetson-nano-2gb-devkit.bin"
INCOMPATIBLE_LICENSE:jetson-nano-2gb-devkit = ""

WKS_FILE:jetson-nano-devkit ?= "jetson-nano-devkit.wks"
IMAGE_FSTYPES:jetson-nano-devkit = "tegraflash tar.gz wic.gz"

IMAGE_BOOT_FILES:jetson-nano-devkit = "Image u-boot.bin tegra210-p3448-0000-p3449-0000-a02.dtb \
		      tegra210-p3448-0000-p3449-0000-b00.dtb u-boot-jetson-nano-devkit.bin"
INCOMPATIBLE_LICENSE:jetson-nano-devkit = ""
#TEGRAFLASH_SDCARD_SIZE:jetson-nano-devkit = "64G"