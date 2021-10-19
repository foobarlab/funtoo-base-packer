#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- basic audio stuff

sudo emerge -nuvtND --with-bdeps=y \
  media-sound/alsa-utils \
  media-sound/pulseaudio

# ---- desktop audio stuff

if [ -z ${BUILD_WINDOW_SYSTEM:-} ]; then
  echo "BUILD_WINDOW_SYSTEM was not set. Skipping ..."
  exit 0
else
  if [ "$BUILD_WINDOW_SYSTEM" = false ]; then
    echo "BUILD_WINDOW_SYSTEM set to FALSE. Skipping ..."
    exit 0
  fi
fi

sudo emerge -nuvtND --with-bdeps=y \
  media-sound/paprefs \
  media-sound/pavucontrol \
  media-sound/pasystray \
  media-sound/pavumeter \
  media-sound/pamix

# TODO add media-sound/alsa-tools?

# ---- sync any guest packages to host (via shared folder)

sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/packages/* $sf_vagrant/packages/
