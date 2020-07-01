#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# net-mail/mailbase: adjust permissions as recommended during install
sudo chown root:mail /var/spool/mail/
sudo chmod 03775 /var/spool/mail/

# sys-apps/mlocate: add shared folder (usually '/vagrant') to /etc/updatedb.conf prune paths to avoid leaking shared files
sudo sed -i 's/PRUNEPATHS="/PRUNEPATHS="\/vagrant /g' /etc/updatedb.conf

sudo emerge -vt @preserved-rebuild

# check dynamic linking consistency
sudo revdep-rebuild
