#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# install 'sbin' scripts to /usr/local/sbin/
sudo chown root.root /tmp/sbin/*
sudo chmod 750 /tmp/sbin/*
sudo cp -f /tmp/sbin/* /usr/local/sbin/

echo "$BUILD_BOX_DESCRIPTION" >> ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' ~vagrant/.release_$BUILD_BOX_NAME

sudo sed -i 's/USE=\"/USE="idn lzma tools udev syslog cacert threads pic gold ncurses /g' /etc/portage/make.conf

# TODO test more USE flags?
#USE="acl acpi bash-completion git hwdb icu iptables kmod lzo networkmanager pci pgo pie posix rdp readline recursion-limit smp udisks unicode unwind upnp utils zlib -systemd"

cat <<'DATA' | sudo tee -a /etc/portage/make.conf

# experimental: add some flags for CPUs after 2011 (intel-nehalem/amd-bulldozer)
#CPU_FLAGS_X86="${CPU_FLAGS_X86} popcnt sse3 sse4_1 sse4_2 ssse3"

# testing: save some space: just install locales "en", "en_US", "de", "fr"
#INSTALL_MASK="/usr/share/locale -/usr/share/locale/en -/usr/share/locale/en_US -/usr/share/locale/de -/usr/share/locale/fr"

# added here, not in profiles yet:
VIDEO_CARDS="virtualbox"

# verbose logging:
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"

DATA

sudo mkdir -p /etc/portage/package.use
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources -binary -custom-cflags
sys-kernel/debian-sources-lts -binary -custom-cflags
sys-kernel/linux-firmware initramfs redistributable
sys-firmware/intel-microcode initramfs
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-rsyslog
app-admin/rsyslog gnutls normalize
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-mc
app-misc/mc -edit -slang
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-portage
sys-apps/portage doc
app-portage/eix doc
DATA

sudo mkdir -p /etc/portage/package.license
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-kernel
sys-kernel/linux-firmware linux-fw-redistributable
DATA

sudo mkdir -p /etc/portage/package.mask
cat <<'DATA' | sudo tee -a /etc/portage/package.mask/base-kernel
# FIXME virtualbox guest additions seem to not compile on newer kernels:
>=sys-kernel/debian-sources-5.5
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
