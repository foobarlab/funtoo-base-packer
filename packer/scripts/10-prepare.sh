#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- copy pre-downloaded distfiles (if any)

sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
if [[ -d "$sf_vagrant/distfiles" ]]; then
  sudo mkdir -p /var/cache/portage/distfiles
  sudo rsync -urv $sf_vagrant/distfiles /var/cache/portage/
  sudo chown -R portage:portage /var/cache/portage/distfiles
  sudo chmod -R 664 /var/cache/portage/distfiles
  sudo chmod 775 /var/cache/portage/distfiles
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

# ---- sync world and cleanup

sudo ego sync
sudo emaint binhost --fix
sudo eclean-dist

# ---- install /usr/local scripts

sudo chown root:root /tmp/sbin/*
sudo chmod 750 /tmp/sbin/*
sudo cp -f /tmp/sbin/* /usr/local/sbin/

# ---- box name

echo "$BUILD_BOX_DESCRIPTION" >> ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<br>/\n/g' ~vagrant/.release_$BUILD_BOX_NAME
sed -i 's/<a .*a>/'$BUILD_GIT_COMMIT_ID'/g' ~vagrant/.release_$BUILD_BOX_NAME

# ---- /etc/motd and /etc/issue

sudo rm -f /etc/motd
cat <<'DATA' | sudo tee -a /etc/motd

Funtoo Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME) - release BUILD_BOX_VERSION build BUILD_TIMESTAMP

DATA
sudo sed -i 's/BUILD_BOX_NAME/'"$BUILD_BOX_NAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/motd
sudo sed -i 's/BUILD_BOX_VERSION/'"$BUILD_BOX_VERSION"'/g' /etc/motd
sudo sed -i 's/BUILD_TIMESTAMP/'"$BUILD_TIMESTAMP"'/g' /etc/motd
sudo cat /etc/motd

sudo rm -f /etc/issue
cat <<'DATA' | sudo tee -a /etc/issue
This is a Funtoo Linux Vagrant Box (BUILD_BOX_USERNAME/BUILD_BOX_NAME-BUILD_BOX_VERSION)

DATA
sudo sed -i 's/BUILD_BOX_VERSION/'$BUILD_BOX_VERSION'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_NAME/'$BUILD_BOX_NAME'/g' /etc/issue
sudo sed -i 's/BUILD_BOX_USERNAME/'"$BUILD_BOX_USERNAME"'/g' /etc/issue
sudo cat /etc/issue

# ---- custom overlay

if [ "$BUILD_CUSTOM_OVERLAY" = true ]; then
  cd /var/git
  sudo mkdir -p overlay || true
  cd overlay
  # FIXME delete if already existing?
  #sudo rm -rf ./$BUILD_CUSTOM_OVERLAY_NAME || true
  # example: git clone --depth 1 -b development "https://github.com/foobarlab/foobarlab-overlay.git" ./foobarlab
  sudo git clone --depth 1 -b $BUILD_CUSTOM_OVERLAY_BRANCH "$BUILD_CUSTOM_OVERLAY_URL" ./$BUILD_CUSTOM_OVERLAY_NAME
  cd ./$BUILD_CUSTOM_OVERLAY_NAME
  # set default strategy:
  #sudo git config pull.rebase true  # merge
  sudo git config pull.ff only       # fast forward only (recommended)
  sudo chown -R portage.portage /var/git/overlay
  cat <<'DATA' | sudo tee -a /etc/portage/repos.conf/$BUILD_CUSTOM_OVERLAY_NAME
[DEFAULT]
main-repo = core-kit

[BUILD_CUSTOM_OVERLAY_NAME]
location = /var/git/overlay/BUILD_CUSTOM_OVERLAY_NAME
auto-sync = no
priority = 10
DATA
  sudo sed -i 's/BUILD_CUSTOM_OVERLAY_NAME/'"$BUILD_CUSTOM_OVERLAY_NAME"'/g' /etc/portage/repos.conf/$BUILD_CUSTOM_OVERLAY_NAME
fi

# remove foobarlab-stage3 repo
sudo rm -rf /var/git/overlay/foobarlab-stage3
sudo rm -f /etc/portage/repos.conf/foobarlab-stage3

# ---- make.conf

# TODO remove all python2 stuff in make.conf? (-python_targets_python2_7 or set PYTHON_TARGETS)

sudo sed -i 's/USE=\"/USE="zsh-completion idn lzma tools udev syslog cacert threads pic ncurses /g' /etc/portage/make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
PORTAGE_ELOG_CLASSES="info warn error log qa"
PORTAGE_ELOG_SYSTEM="echo save save_summary"

MAKEOPTS="BUILD_MAKEOPTS"
FEATURES="buildpkg userfetch"

# enable binary packages with excludes
EMERGE_DEFAULT_OPTS="--usepkg --binpkg-respect-use=y"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --buildpkg-exclude 'virtual/* sys-kernel/*-sources app-emulation/virtualbox*'"
EMERGE_DEFAULT_OPTS="${EMERGE_DEFAULT_OPTS} --usepkg-exclude 'virtual/* sys-kernel/*-sources app-emulation/virtualbox*'"

# testing: only install english locales (saves some space)
INSTALL_MASK="/usr/share/locale -/usr/share/locale/en"
INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_AU"
INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_CA"
INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_GB"
INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en_US"
INSTALL_MASK="${INSTALL_MASK} -/usr/share/locale/en@shaw"

CURL_SSL="gnutls"

DATA
sudo sed -i 's/BUILD_MAKEOPTS/'"${BUILD_MAKEOPTS}"'/g' /etc/portage/make.conf

# ---- package.use

sudo mkdir -p /etc/portage/package.use
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-kernel
sys-kernel/genkernel -cryptsetup
sys-kernel/debian-sources -logo -binary -custom-cflags
sys-kernel/debian-sources-lts -logo -binary -custom-cflags
sys-kernel/linux-firmware initramfs redistributable
sys-firmware/intel-microcode initramfs
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base
sys-libs/ncurses tinfo
app-admin/rsyslog gnutls normalize
app-misc/mc -edit -slang
sys-apps/portage doc
app-portage/eix doc
media-fonts/terminus-font distinct-l
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-firewall
net-firewall/iptables conntrack netlink nftables pcap
net-firewall/nftables json
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-python2-removal
# try to disable all python2 stuff
app-admin/ansible -python_targets_python2_7
dev-vcs/git -python_targets_python2_7
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-audio
media-plugins/alsa-plugins pulseaudio
DATA
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-gmp
>=dev-libs/gmp-6.2.1-r1 static-libs
DATA
#cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-pulseaudio
# TODO add non-x11 pulseaudio flags?
#DATA

# ---- package.license

sudo mkdir -p /etc/portage/package.license
cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-llvm
>=sys-devel/llvm-9.0 Apache-2.0-with-LLVM-exceptions
>=sys-devel/llvm-common-9.0 Apache-2.0-with-LLVM-exceptions
DATA

cat <<'DATA' | sudo tee -a /etc/portage/package.license/curl
>=net-misc/curl-7.83.1 curl
DATA

# ---- set profiles

sudo epro mix-ins +no-systemd +console-extras +audio +media

if [[ -n "$BUILD_FLAVOR" ]]; then
    sudo epro flavor $BUILD_FLAVOR
fi

sudo epro list

# ---- cleanup python

# set default python
sudo eselect python list
sudo eselect python cleanup
sudo eselect python set python3.7
sudo eselect python list

# ---- set locales

sudo locale-gen
sudo eselect locale set en_US.UTF-8
source /etc/profile

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

sudo epro mix-ins +X +gfxcard-vmware +gnome
sudo epro list

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
VIDEO_CARDS="virtualbox vmware gallium-vmware xa dri3"

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
cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-gnome
# needed for 'nm-applet':
#>=app-crypt/pinentry-1.1.1 gnome-keyring

# needed for gnome profile:
>=net-libs/libpsl-0.20.2 -idn -icu idn2

DATA

cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA
