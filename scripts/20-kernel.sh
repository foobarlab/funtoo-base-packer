#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_KERNEL:-} ]; then
    echo "BUILD_KERNEL was not set. Skipping kernel build."
    exit 0
else
    if [ "$BUILD_KERNEL" = false ]; then
        echo ">>> Skipping kernel build."
        exit 0
    else
        echo ">>> Building kernel ..."
    fi
fi

if [ -f ${scripts}/scripts/kernel.config ]; then
	if [ -f /usr/src/kernel.config ]; then
		KERNEL_RELEASE=$(uname -r)
		sudo mv -f /usr/src/kernel.config /usr/src/kernel.config.${KERNEL_RELEASE}
	fi
	sudo cp ${scripts}/scripts/kernel.config /usr/src
fi

sudo emerge -nuvtND --with-bdeps=y sys-kernel/genkernel
sudo mv /etc/genkernel.conf /etc/genkernel.conf.old

cat <<'DATA' | sudo tee -a /etc/genkernel.conf
INSTALL="yes"
OLDCONFIG="yes"
MENUCONFIG="no"
CLEAN="yes"
MRPROPER="yes"
MOUNTBOOT="yes"
SYMLINK="no"
SAVE_CONFIG="no"
USECOLOR="yes"
CLEAR_CACHE_DIR="yes"
POSTCLEAR="1"
MAKEOPTS="BUILD_MAKEOPTS"
LVM="no"
LUKS="no"
GPG="no"
DMRAID="no"
SSH="no"
BUSYBOX="no"
MDADM="no"
MULTIPATH="no"
ISCSI="no"
UNIONFS="no"
BTRFS="no"
DISKLABEL="yes"
BOOTLOADER=""	# 'grub' value not needed here, we will use ego boot update command
BOOTDIR="/boot"
GK_SHARE="${GK_SHARE:-/usr/share/genkernel}"
CACHE_DIR="/usr/share/genkernel"
DISTDIR="${CACHE_DIR}/src"
LOGFILE="/var/log/genkernel.log"
LOGLEVEL=1
DEFAULT_KERNEL_SOURCE="/usr/src/linux"
DEFAULT_KERNEL_CONFIG="/usr/src/kernel.config"
COMPRESS_INITRD="yes"
COMPRESS_INITRD_TYPE="best"
#NETBOOT="1"
CMD_CALLBACK="emerge -vt @module-rebuild"
#REAL_ROOT="/dev/sda4"
DATA

sudo sed -i 's/BUILD_MAKEOPTS/'"$BUILD_MAKEOPTS"'/g' /etc/genkernel.conf

sudo env-update
source /etc/profile

sudo eclean-kernel -l
sudo eselect kernel list

sudo emerge -nuvtND --with-bdeps=y sys-kernel/debian-sources

sudo eselect kernel list
sudo eselect kernel set 1
sudo eselect kernel list
sudo eclean-kernel -l

cd /usr/src/linux

# apply 'make olddefconfig' on 'kernel.config' in case kernel config is outdated
sudo cp -f /usr/src/kernel.config /usr/src/kernel.config.bak
sudo mv -f /usr/src/kernel.config /usr/src/linux/.config
sudo make olddefconfig
sudo mv -f /usr/src/linux/.config /usr/src/kernel.config
sudo cp -f /usr/src/kernel.config /usr/src/kernel.config.base-dist

sudo genkernel all

cd /usr/src

sudo env-update
source /etc/profile

sudo mv /etc/boot.conf /etc/boot.conf.old
cat <<'DATA' | sudo tee -a /etc/boot.conf
boot {
    generate grub
    default "Funtoo Linux"
    timeout 1
}
display {
	gfxmode 800x600
}
"Funtoo Linux" {
    kernel kernel[-v]
    initrd initramfs[-v]
    params += root=auto rootfstype=auto
}
DATA

sudo ego boot update
