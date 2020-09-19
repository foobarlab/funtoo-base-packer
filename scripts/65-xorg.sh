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
# testing:
#VIDEO_CARDS="virtualbox"

DATA

# ---- set required USE flags

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
# required for funtoo profile 'X':
>=media-libs/gd-2.2.5-r2 fontconfig jpeg truetype png
>=media-libs/mesa-20.1.6 video_cards_xa
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

sudo emerge -vt x11-base/xorg-x11

# ---- install fluxbox

cat <<'DATA' | sudo tee -a /etc/portage/package.use/base-xorg
>=x11-wm/fluxbox-1.3.7 vim-syntax
DATA

sudo emerge -vt x11-wm/fluxbox
