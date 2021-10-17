#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- re-sync meta-repo and overlays

sudo env-update
source /etc/profile
sudo ego sync

# ---- clean bin pkgs

sudo emaint binhost --fix
sudo eclean packages

# ---- clean distfiles

sudo eclean-dist
