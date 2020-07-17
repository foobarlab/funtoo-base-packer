#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

echo "$BUILD_BOX_DESCRIPTION" >> /home/vagrant/.$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' /home/vagrant/.$BUILD_BOX_NAME

# TODO setup USE flags: might need to enable some more, e.g.:
#USE="acl acpi bash-completion bindist cacert git gold hwdb icu idn iptables kmod lzma lzo networkmanager ncurses pci pgo pic pie posix rdp readline recursion-limit smp syslog threads tools udev udisks unicode unwind upnp utils zlib -systemd"

sudo sed -i 's/USE=\"/USE="idn lzma tools udev syslog cacert threads pic gold ncurses /g' /etc/portage/make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
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
# FIXME required for firmware?
#sys-firmware/intel-microcode initramfs
DATA

sudo mkdir -p /etc/portage/package.license
cat <<'DATA' | sudo tee -a /etc/portage/package.license/vbox-kernel
sys-kernel/linux-firmware linux-fw-redistributable
DATA

sudo mkdir -p /etc/portage/package.mask
cat <<'DATA' | sudo tee -a /etc/portage/package.mask/vbox-kernel
# FIXME virtualbox guest additions seem to not compile on newer kernels:
>=sys-kernel/debian-sources-5.5
DATA

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

sudo eselect python list
sudo eselect python set python3.7
sudo eselect python list

sudo rm -f /etc/motd
cat <<'DATA' | sudo tee -a /etc/motd

Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP

DATA
sudo sed -i 's/BUILD_BOX_NAME/'"$BUILD_BOX_NAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_VERSION/'"$BUILD_BOX_VERSION"'/g' /etc/motd
sudo sed -i 's/BUILD_TIMESTAMP/'"$BUILD_TIMESTAMP"'/g' /etc/motd
sudo cat /etc/motd

sudo mv -f /etc/issue /etc/issue.old
cat <<'DATA' | sudo tee -a /etc/issue
This is a Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME BUILD_BOX_VERSION)

DATA
sudo sed -i 's/BUILD_BOX_VERSION/'$BUILD_BOX_VERSION'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_NAME/'$BUILD_BOX_NAME'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/issue
sudo cat /etc/issue

sudo locale-gen
sudo eselect locale set en_US.UTF-8
source /etc/profile

sudo emerge -1v portage ego
sudo env-update
source /etc/profile
sudo ego sync
