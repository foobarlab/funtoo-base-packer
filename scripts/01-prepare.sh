#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

echo "$BUILD_BOX_DESCRIPTION" >> /home/vagrant/.$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' /home/vagrant/.$BUILD_BOX_NAME

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
# TODO reduce USE flags: delete the following line
#USE="acl acpi bash-completion bindist cacert git gold hwdb icu idn iptables kmod lzma lzo networkmanager ncurses pci pgo pic pie posix rdp readline recursion-limit smp syslog threads tools udev udisks unicode unwind upnp utils zlib -systemd"
USE="idn lzma tools udev binddist syslog cacert threads pic"
VIDEO_CARDS="virtualbox"
# verbose logging:
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"
DATA

sudo mkdir -p /etc/portage/package.use
cat <<'DATA' | sudo tee -a /etc/portage/package.use/vbox-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources -binary -custom-cflags
sys-kernel/debian-sources-lts -binary -custom-cflags
# FIXME firmware needed?
#sys-firmware/intel-microcode initramfs
DATA

# FIXME firmware needed?
#sudo mkdir -p /etc/portage/package.license
#cat <<'DATA' | sudo tee -a /etc/portage/package.license/vbox-kernel
#sys-kernel/linux-firmware linux-fw-redistributable
#DATA

cat <<'DATA' | sudo tee -a /etc/portage/package.use/vbox-defaults
app-admin/rsyslog gnutls normalize
app-misc/mc -edit -slang
DATA

sudo ego sync

sudo epro mix-ins +no-systemd +console-extras

if [[ -n "$BUILD_FLAVOR" ]]; then
    sudo epro flavor $BUILD_FLAVOR
fi

sudo epro list

lsblk

sudo rm -f /etc/motd
cat <<'DATA' | sudo tee -a /etc/motd
Funtoo GNU/Linux (BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP
DATA
sudo sed -i 's/BUILD_BOX_NAME/'"$BUILD_BOX_NAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_VERSION/'"$BUILD_BOX_VERSION"'/g' /etc/motd
sudo sed -i 's/BUILD_TIMESTAMP/'"$BUILD_TIMESTAMP"'/g' /etc/motd
sudo cat /etc/motd

sudo locale-gen
sudo eselect locale set en_US.UTF-8
source /etc/profile

# added for robustness:
sudo emerge -1v portage ego

sudo env-update
source /etc/profile
