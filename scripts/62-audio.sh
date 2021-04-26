#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- basic audio stuff

sudo emerge -nuvtND --with-bdeps=y \
    media-sound/pulseaudio \
    media-sound/alsa-tools \
    media-sound/alsa-utils \
    media-sound/paprefs \
    media-sound/pavucontrol \
    media-sound/pasystray \
    media-sound/pavumeter \
    media-sound/pamix

# sync any guest packages to host (via shared folder)
sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/packages/* $sf_vagrant/packages/
