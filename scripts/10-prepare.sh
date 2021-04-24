#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- import binary packages

sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
mkdir -p $sf_vagrant/packages || true
sudo mkdir -p /var/cache/portage/packages || true
sudo rsync -urv $sf_vagrant/packages /var/cache/portage/
sudo chown -R root:root /var/cache/portage/packages
sudo find /var/cache/portage/packages/ -type d -exec chmod 755 {} +
sudo find /var/cache/portage/packages/ -type f -exec chmod 644 {} +
sudo chown root:portage /var/cache/portage/packages
sudo chmod 775 /var/cache/portage/packages

# ---- install /usr/local scripts

sudo chown root:root /tmp/sbin/*
sudo chmod 750 /tmp/sbin/*
sudo cp -f /tmp/sbin/* /usr/local/sbin/

# ---- box name

echo "$BUILD_BOX_DESCRIPTION" >> ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<a .*a>/'$BUILD_GIT_COMMIT_ID'/g' ~vagrant/.release_$BUILD_BOX_NAME

# ---- make.conf

sudo sed -i 's/USE=\"/USE="zsh-completion idn lzma tools udev syslog cacert threads pic ncurses /g' /etc/portage/make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"

MAKEOPTS="BUILD_MAKEOPTS"
FEATURES="buildpkg userfetch"

# enable binary packages with excludes
EMERGE_DEFAULT_OPTS="--usepkg --binpkg-respect-use=y"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --buildpkg-exclude 'virtual/* */*-bin sys-apps/* sys-kernel/*-sources app-emulation/virtualbox-guest-additions'"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --usepkg-exclude 'virtual/* */*-bin sys-apps/* sys-kernel/*-sources app-emulation/virtualbox-guest-additions'"

# testing: only english locales (saves some space)
#INSTALL_MASK="/usr/share/locale -/usr/share/locale/en"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_AU"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_CA"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_GB"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_US"
#INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en@shaw"

DATA
sudo sed -i 's/BUILD_MAKEOPTS/'"${BUILD_MAKEOPTS}"'/g' /etc/portage/make.conf

# ---- package.use

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

# ---- re-sync and clean binary packages

sudo ego sync
sudo eclean packages

# ---- set profiles

sudo epro mix-ins +no-systemd +console-extras +audio +media

if [[ -n "$BUILD_FLAVOR" ]]; then
    sudo epro flavor $BUILD_FLAVOR
fi

sudo epro list

# ---- cleanup python

sudo eselect python list
sudo eselect python cleanup
sudo eselect python set python3.7
sudo eselect python list

# ---- /etc/motd and /etc/issue

sudo rm -f /etc/motd
cat <<'DATA' | sudo tee -a /etc/motd

Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP

DATA
sudo sed -i 's/BUILD_BOX_NAME/'"$BUILD_BOX_NAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_VERSION/'"$BUILD_BOX_VERSION"'/g' /etc/motd
sudo sed -i 's/BUILD_TIMESTAMP/'"$BUILD_TIMESTAMP"'/g' /etc/motd
sudo cat /etc/motd

sudo rm -f /etc/issue
cat <<'DATA' | sudo tee -a /etc/issue
This is a Funtoo GNU/Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME BUILD_BOX_VERSION)

DATA
sudo sed -i 's/BUILD_BOX_VERSION/'$BUILD_BOX_VERSION'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_NAME/'$BUILD_BOX_NAME'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/issue
sudo cat /etc/issue

# ---- set locales

sudo locale-gen
sudo eselect locale set en_US.UTF-8
source /etc/profile

# ---- re-sync meta-repo and overlays

sudo env-update
source /etc/profile
sudo ego sync

# ---- build X11?

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
VIDEO_CARDS="virtualbox vmware gallium-vmware xa dri3"

DATA

sudo mkdir -p /etc/portage/package.use
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

sudo mkdir -p /etc/portage/package.license
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA
# FIXME needed when not building X11?
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-llvm
>=sys-devel/llvm-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/llvm-common-9.0 Apache-2.0-with-LLVM-exceptions
DATA
