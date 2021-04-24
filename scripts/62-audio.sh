#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- basic audio stuff

sudo emerge -nuvtND --with-bdeps=y \
    media-sound/pulseaudio
