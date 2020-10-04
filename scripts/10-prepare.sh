#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# import binary packages
mkdir -p /tmp/packages || true
echo "$BUILD_BOX_DESCRIPTION" >> /tmp/packages/.release_$BUILD_BOX_NAME-$BUILD_BOX_VERSION
sudo mkdir -p /var/cache/portage/packages || true # TODO check if needed, set with rsync?
sudo rsync -urv /tmp/packages /var/cache/portage/
sudo chown -R root:root /var/cache/portage/packages
sudo find /var/cache/portage/packages/ -type d -exec chmod 755 {} +
sudo find /var/cache/portage/packages/ -type f -exec chmod 644 {} +
sudo chown root:portage /var/cache/portage/packages
sudo chmod 775 /var/cache/portage/packages

# install /usr/local scripts
sudo chown root:root /tmp/sbin/*
sudo chmod 750 /tmp/sbin/*
sudo cp -f /tmp/sbin/* /usr/local/sbin/

echo "$BUILD_BOX_DESCRIPTION" >> ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' ~vagrant/.release_$BUILD_BOX_NAME

# TODO experimental
#sudo sed -i 's/USE=\"/USE="gold /g' /etc/portage/make.conf

sudo sed -i 's/USE=\"/USE="zsh-completion idn lzma tools udev syslog cacert threads pic ncurses /g' /etc/portage/make.conf

BUILD_EXCLUDE_BINARIES="${BUILD_EXCLUDE_BINARIES} virtual/*"
BUILD_EXCLUDE_BINARIES="${BUILD_EXCLUDE_BINARIES} */*-bin"
BUILD_EXCLUDE_BINARIES="${BUILD_EXCLUDE_BINARIES} sys-apps/*"
BUILD_EXCLUDE_BINARIES="${BUILD_EXCLUDE_BINARIES} sys-kernel/*-sources"
BUILD_EXCLUDE_BINARIES="${BUILD_EXCLUDE_BINARIES} app-emulation/virtualbox-guest-additions"

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"

MAKEOPTS="BUILD_MAKEOPTS"
FEATURES="buildpkg userfetch"

# testing: enable binary packages
EMERGE_DEFAULT_OPTS="--usepkg"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --buildpkg-exclude 'BUILD_EXCLUDE_BINARIES'"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --usepkg-exclude 'BUILD_EXCLUDE_BINARIES'"

# testing: only english locales (saves some space)
#INSTALL_MASK="/usr/share/locale -/usr/share/locale/en"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_AU"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_CA"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_GB"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_US"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en@shaw"

DATA
sudo sed -i 's/BUILD_MAKEOPTS/'"$BUILD_MAKEOPTS"'/g' /etc/portage/make.conf
sudo sed -i 's/BUILD_EXCLUDE_BINARIES/'"$BUILD_EXCLUDE_BINARIES"'/g' /etc/portage/make.conf

sudo mkdir -p /etc/portage/package.use
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources -binary -custom-cflags
sys-kernel/debian-sources-lts -binary -custom-cflags
sys-kernel/linux-firmware initramfs redistributable
sys-firmware/intel-microcode initramfs
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base
app-admin/rsyslog gnutls normalize
app-misc/mc -edit -slang
sys-apps/portage doc
app-portage/eix doc
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

sudo ego sync
sudo eclean packages

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

if [ -z ${BUILD_WINDOW_SYSTEM:-} ]; then
  echo "BUILD_WINDOW_SYSTEM was not set. Skipping ..."
  exit 0
else
  if [ "$BUILD_WINDOW_SYSTEM" = false ]; then
    echo "BUILD_WINDOW_SYSTEM set to FALSE. Skipping ..."
    exit 0
  fi
fi

echo "BUILD_WINDOW_SYSTEM set to True. Preparing Portage ..."

# FIXME check build config for compatibility:
# - should BUILD_KERNEL be set to 'true'?
# - should BUILD_HEADLESS be set to 'true'?

sudo epro mix-ins +X +gfxcard-vmware
sudo epro list

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
#VIDEO_CARDS="virtualbox vmware gallium-vmware xa dri3" # FIXME virtualbox/vbox-video fails on build
VIDEO_CARDS="vmware gallium-vmware xa dri3"

DATA

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
# required for funtoo profile 'X':
media-libs/gd fontconfig jpeg truetype png

# required for 'lightdm':
sys-auth/consolekit policykit

# required for 'xinit':
x11-apps/xinit -minimal

# required for TrueType support:
x11-terms/xterm truetype
x11-libs/libXfont2 truetype

DATA

cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA

# TODO try also without llvm? (mesa USE -llvm)
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-llvm
>=sys-devel/llvm-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/llvm-common-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/clang-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/clang-common-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/compiler-rt-sanitizers-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/compiler-rt-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/libomp-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-libs/llvm-libunwind-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/lld-9.0 Apache-2.0-with-LLVM-exceptions
>=dev-util/lldb-9.0 Apache-2.0-with-LLVM-exceptions
DATA
