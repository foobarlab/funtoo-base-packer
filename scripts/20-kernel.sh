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

if [ -f ${SCRIPTS}/scripts/kernel.config ]; then
	if [ -f /usr/src/kernel.config ]; then
		KERNEL_RELEASE=$(uname -r)
		sudo mv -f /usr/src/kernel.config /usr/src/kernel.config.${KERNEL_RELEASE}
	fi
	sudo cp ${SCRIPTS}/scripts/kernel.config /usr/src
fi

sudo emerge -vt sys-kernel/genkernel
sudo mv /etc/genkernel.conf /etc/genkernel.conf.dist

cat <<'DATA' | sudo tee -a /etc/genkernel.conf
INSTALL="yes"
OLDCONFIG="yes"
MENUCONFIG="no"
CLEAN="yes"
MRPROPER="yes"
#ARCH_OVERRIDE="x86"
MOUNTBOOT="yes"
SYMLINK="no"
SAVE_CONFIG="no"
USECOLOR="yes"
CLEAR_CACHE_DIR="yes"
POSTCLEAR="1"
#MAKEOPTS="-j2"	# better determined by Vagrantfile
LVM="no"
LUKS="no"
GPG="no"
DMRAID="no"
SSH="no"
BUSYBOX="no"
MDADM="no"
#MDADM_CONFIG="/etc/mdadm.conf"
MULTIPATH="no"
ISCSI="no"
UNIONFS="no"
BTRFS="no"
#FIRMWARE="no"
#FIRMWARE_SRC="/lib/firmware"
#FIRMWARE_FILES="/lib/firmware/amd/amd_sev_fam17h_model0xh.sbin,/lib/firmware/amd-ucode/microcode_amd_fam17h.bin,/lib/firmware/amd-ucode/microcode_amd_fam17h.bin.asc,/lib/firmware/amd-ucode/microcode_amd_fam15h.bin,/lib/firmware/amd-ucode/microcode_amd_fam15h.bin.asc,/lib/firmware/amd-ucode/microcode_amd_fam16h.bin.asc,/lib/firmware/amd-ucode/microcode_amd.bin,/lib/firmware/amd-ucode/microcode_amd_fam16h.bin,/lib/firmware/amd-ucode/microcode_amd.bin.asc"
DISKLABEL="yes"
BOOTLOADER=""	# 'grub' value not needed here, we will use ego boot update command
#SPLASH="yes"
#SPLASH_THEME="gentoo"
#DOKEYMAPAUTO="yes"
#KEYMAP="0"
#KERNEL_MAKE="make"
#KERNEL_CC="gcc"
#KERNEL_AS="as"
#KERNEL_LD="ld"
#UTILS_MAKE="make"
#UTILS_CC="gcc"
#UTILS_AS="as"
#UTILS_LD="ld"
#UTILS_CROSS_COMPILE="x86_64-pc-linux-gnu"
#KERNEL_CROSS_COMPILE="x86_64-pc-linux-gnu"
#TMPDIR="/var/tmp/genkernel"
BOOTDIR="/boot"
GK_SHARE="${GK_SHARE:-/usr/share/genkernel}"
CACHE_DIR="/usr/share/genkernel"
DISTDIR="${CACHE_DIR}/src"
LOGFILE="/var/log/genkernel.log"
LOGLEVEL=2
DEFAULT_KERNEL_SOURCE="/usr/src/linux"
DEFAULT_KERNEL_CONFIG="/usr/src/kernel.config"
#BUSYBOX_CONFIG="/path/to/file"
#BUSYBOX_VER="1.21.1"
#BUSYBOX_SRCTAR="${DISTDIR}/busybox-${BUSYBOX_VER}.tar.bz2"
#BUSYBOX_DIR="busybox-${BUSYBOX_VER}"
#BUSYBOX_BINCACHE="%%CACHE%%/busybox-${BUSYBOX_VER}-%%ARCH%%.tar.bz2"
#BUSYBOX_APPLETS="[ ash sh mount uname echo cut cat"
#DMRAID_VER="1.0.0.rc16-3"
#DMRAID_DIR="dmraid/${DMRAID_VER}/dmraid"
#DMRAID_SRCTAR="${DISTDIR}/dmraid-${DMRAID_VER}.tar.bz2"
#DMRAID_BINCACHE="%%CACHE%%/dmraid-${DMRAID_VER}-%%ARCH%%.tar.bz2"
#ISCSI_VER="2.0.877"
#ISCSI_DIR="open-iscsi-${ISCSI_VER}"
#ISCSI_SRCTAR="${DISTDIR}/open-iscsi-${ISCSI_VER}.tar.gz"
#ISCSI_BINCACHE="%%CACHE%%/iscsi-${ISCSI_VER}-%%ARCH%%.bz2"
#FUSE_VER="2.8.6"
#FUSE_DIR="fuse-${FUSE_VER}"
#FUSE_SRCTAR="${DISTDIR}/fuse-${FUSE_VER}.tar.gz"
#FUSE_BINCACHE="%%CACHE%%/fuse-${FUSE_VER}-%%ARCH%%.tar.bz2"
#UNIONFS_FUSE_VER="0.24"
#UNIONFS_FUSE_DIR="unionfs-fuse-${UNIONFS_FUSE_VER}"
#UNIONFS_FUSE_SRCTAR="${DISTDIR}/unionfs-fuse-${UNIONFS_FUSE_VER}.tar.bz2"
#UNIONFS_FUSE_BINCACHE="%%CACHE%%/unionfs-fuse-${UNIONFS_FUSE_VER}-%%ARCH%%.bz2"
#GPG_VER="1.4.11"
#GPG_DIR="gnupg-${GPG_VER}"
#GPG_SRCTAR="${DISTDIR}/gnupg-${GPG_VER}.tar.bz2"
#GPG_BINCACHE="%%CACHE%%/gnupg-${GPG_VER}-%%ARCH%%.bz2"
#KNAME="genkernel"
#KERNEL_SOURCES="0"
#BUILD_STATIC="1"
#GENZIMAGE="1"
#KERNCACHE="/path/to/file"
#INSTALL_MOD_PATH=""
#ALLRAMDISKMODULES="1"
#RAMDISKMODULES="0"
#MINKERNPACKAGE="/path/to/file.bz2"
#MODULESPACKAGE="/path/to/file.bz2"
#INITRAMFS_OVERLAY=""
#INTEGRATED_INITRAMFS="1"
COMPRESS_INITRD="yes"
COMPRESS_INITRD_TYPE="best"
#NETBOOT="1"
CMD_CALLBACK="emerge -vt @module-rebuild"
REAL_ROOT="/dev/sda4"
DATA

sudo env-update
source /etc/profile

sudo eselect kernel list
sudo emerge --unmerge sys-kernel/debian-sources-lts
sudo emerge -vt sys-kernel/debian-sources

#sudo emerge -vt sys-kernel/linux-firmware    # TODO enable for AMD microcode? strip down included firmware files

sudo eselect kernel list
sudo eselect kernel set 1
sudo eselect kernel list

cd /usr/src/linux

# apply 'make olddefconfig' on 'kernel.config' in case kernel config is outdated
sudo cp -f /usr/src/kernel.config /usr/src/kernel.config.bak
sudo mv -f /usr/src/kernel.config /usr/src/linux/.config
sudo make olddefconfig
sudo mv -f /usr/src/linux/.config /usr/src/kernel.config
sudo cp /usr/src/kernel.config /usr/src/kernel.config.base-dist

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
    params += real_root=/dev/sda4 root=PARTLABEL=rootfs rootfstype=ext4
}
DATA

sudo ego boot update
