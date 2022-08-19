#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- update world

sudo emerge -vtuDN --with-bdeps=y --binpkg-changed-deps=y --complete-graph=y @world
sudo emerge -vt @preserved-rebuild
sudo emerge --depclean
sudo emerge -vt @preserved-rebuild

# ---- remove known obsolete config files

sudo rm -f /etc/conf.d/._cfg0000_hostname

sudo find /etc/ -name '._cfg*'        # DEBUG: list all config files needing an update
sudo find /etc/ -name '._cfg*' -print -exec cat -n '{}' \;  # DEBUG: cat all config files needing an update

sudo etc-update --verbose --preen    # auto-merge trivial changes

# ---- update environment

sudo env-update
source /etc/profile

# ---- sync binary packages

sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/packages/* $sf_vagrant/packages/
