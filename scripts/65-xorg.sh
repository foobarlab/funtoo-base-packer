#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_WINDOW_SYSTEM:-} ]; then
  echo "BUILD_WINDOW_SYSTEM was not set. Skipping ..."
  exit 0
else
  if [ "$BUILD_WINDOW_SYSTEM" = false ]; then
    echo "BUILD_WINDOW_SYSTEM set to FALSE. Skipping ..."
    exit 0
  fi
fi

# ---- console mouse support

sudo emerge -vt sys-libs/gpm
sudo rc-update add gpm default

# ---- set make.conf

cat <<'DATA' | sudo tee -a /etc/portage/make.conf
#VIDEO_CARDS="virtualbox"
VIDEO_CARDS="vmware gallium-vmware"

DATA

# ---- set required USE flags

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
# required for funtoo profile 'X':
>=media-libs/gd-2.2.5-r2 fontconfig jpeg truetype png
>=media-libs/mesa-20.1.6 video_cards_xa

# required for 'lightdm':
>=sys-auth/consolekit-1.2.1 policykit

# required by 'nm-applet':
>=app-crypt/pinentry-1.1.0-r3 gnome-keyring

# required for 'xinit':
>=x11-apps/xinit-1.4.1 -minimal

# required by 'x11-drivers/xf86-video-vmware':
>=x11-libs/libdrm-2.4.101 video_cards_vmware

DATA

# ---- set required licenses

cat <<'DATA' | sudo tee -a /etc/portage/package.license/base-xorg
# required for funtoo profile 'X':
>=media-libs/libpng-1.6.37 libpng2
DATA

# ---- set 'X' profile

sudo epro mix-ins +X +gfxcard-vmware
sudo epro list

# ---- update system

sudo emerge -vtuDN --with-bdeps=y @world
sudo etc-update --verbose --preen
sudo emerge -vt @preserved-rebuild

sudo env-update
source /etc/profile

# ---- install xorg server

sudo emerge -vt \
	x11-base/xorg-x11 \
	x11-apps/xinit \
	x11-drivers/xf86-video-vmware

cat <<'DATA' | sudo tee -a /etc/X11/xorg.conf.d/10video.conf
# set vmware video driver
# see: see: https://forums.virtualbox.org/viewtopic.php?f=3&t=96378
Section "Device"
  BoardName    "VirtualBox Graphics"
  Driver       "vmware"
  Identifier   "Device[0]"
  VendorName   "Oracle Corporation"
EndSection
DATA

cat <<'DATA' | sudo tee -a /etc/X11/xorg.conf.d/30keyboard.conf
# set us-international keyboard
# see: https://blechtog.wordpress.com/2012/05/25/gentoo-config-for-us-international-keyboard-layout/
# see https://zuttobenkyou.wordpress.com/2011/08/24/xorg-using-the-us-international-altgr-intl-variant-keyboard-layout/
Section "InputClass"
        Identifier "keyboard-all"
        Option "XkbLayout" "us"
        #Option "XkbModel" "pc105"
        Option "XkbVariant" "altgr-intl"
        #MatchIsKeyboard "on"
EndSection
Section "InputClass"
        Identifier "keyboard-all"
        MatchIsKeyboard "on"
        Option "XkbLayout" "us"
        Option "XkbVariant" "altgr-intl"
EndSection
DATA

sudo gpasswd -a vagrant video  # FIXME is this needed?

# ---- install display / window manager

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
>=x11-wm/fluxbox-1.3.7 vim-syntax
DATA

sudo emerge -vt \
	x11-wm/fluxbox \
	x11-misc/lightdm \
	sys-auth/elogind

sudo sed -i 's/DISPLAYMANAGER=\"xdm\"/DISPLAYMANAGER=\"lightdm\"/g' /etc/conf.d/xdm

# TODO configure lightdm: /etc/lightdm/lightdm.conf
# TODO configure lightdm: /etc/lightdm/lightdm-gtk-greeter.conf

sudo rc-update add xdm default

# ---- install utils

sudo emerge -vt \
	x11-terms/xterm \
	gnome-extra/nm-applet