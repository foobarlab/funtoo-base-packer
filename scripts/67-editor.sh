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

# ---- install additional editors

sudo emerge -nuvtND --with-bdeps=y \
    app-editors/gvim \
    app-editors/leafpad

# ---- customize fluxbox

# TODO customize fluxbox usermenu

fluxbox-generate_menu -is -ds
