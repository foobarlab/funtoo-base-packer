#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

sudo emerge -vtuDN --with-bdeps=y @world

sudo emerge -vt @preserved-rebuild

# remove known obsolete config files
sudo rm -f /etc/conf.d/._cfg0000_hostname

sudo find /etc/ -name '._cfg*'				# DEBUG: list all config files needing an update
sudo find /etc/ -name '._cfg*' -print -exec cat -n '{}' \;  # DEBUG: cat all config files needing an update

sudo etc-update --verbose --preen

sudo env-update
source /etc/profile

# sync any guest packages to host (via shared folder)
sudo rsync -urv /var/cache/portage/packages/* /vagrant/packages/
