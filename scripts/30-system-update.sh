#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

sudo emerge -vtuDN --with-bdeps=y @world

sudo etc-update --verbose --preen

sudo emerge -vt @preserved-rebuild

sudo env-update
source /etc/profile
