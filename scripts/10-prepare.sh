#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# install /usr/local scripts
sudo chown root.root /tmp/sbin/*
sudo chmod 750 /tmp/sbin/*
sudo cp -f /tmp/sbin/* /usr/local/sbin/

echo "$BUILD_BOX_DESCRIPTION" >> ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' ~vagrant/.release_$BUILD_BOX_NAME

# TODO experimental
#sudo sed -i 's/USE=\"/USE="gold /g' /etc/portage/make.conf

sudo sed -i 's/USE=\"/USE="zsh-completion idn lzma tools udev syslog cacert threads pic ncurses /g' /etc/portage/make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"

#EMERGE_DEFAULT_OPTS="--keep-going"

CURL_SSL="libressl"

DATA

sudo mkdir -p /etc/portage/package.use
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources -binary -custom-cflags
sys-kernel/debian-sources-lts -binary -custom-cflags
sys-kernel/linux-firmware initramfs redistributable
sys-firmware/intel-microcode initramfs
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-misc
app-admin/rsyslog gnutls normalize
app-misc/mc -edit -slang
sys-apps/portage doc
app-portage/eix doc
>=net-misc/curl-7.65.1 http2
net-libs/nghttp2 libressl
media-fonts/terminus-font distinct-l
DATA

sudo mkdir -p /etc/portage/package.mask
cat <<'DATA' | sudo tee -a /etc/portage/package.mask/base-ansible
>=app-admin/ansible-2.10.0
DATA

sudo mkdir -p /etc/portage/package.license
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-kernel
sys-kernel/linux-firmware linux-fw-redistributable
DATA

sudo mkdir -p /etc/portage/package.accept_keywords
cat <<'DATA' | sudo tee -a /etc/portage/package.accept_keywords/base-libressl
dev-libs/libressl **
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
