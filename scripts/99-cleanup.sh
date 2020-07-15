#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

sudo env-update
source /etc/profile

sudo emerge --depclean

sudo find /etc/ -name '._cfg*'				# DEBUG: list all config files needing an update
sudo etc-update --verbose --preen			# auto-merge trivial changes

# prevent replacement of our modified configs:
sudo rm -f /etc/._cfg0000_boot.conf
sudo rm -f /etc/._cfg0000_genkernel.conf
sudo rm -f /etc/._cfg0000_updatedb.conf

sudo find /etc/ -name '._cfg*'				# DEBUG: list all remaining config files needing an update
sudo etc-update --verbose --automode -5		# force 'auto-merge' for remaining configs

sudo eselect kernel list
sudo ego boot update

sudo rm -f /etc/resolv.conf
sudo rm -f /etc/resolv.conf.bak
sudo rm -rf /var/cache/portage/distfiles/*
sudo rm -rf /var/git/meta-repo

sudo sync

# simple way to claim some free space before export
sudo bash -c 'dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null' || true
sudo rm -f /EMPTY

bash -c 'cat /dev/null > ~/.bash_history && history -c && exit'
