#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# ---- update environment

sudo env-update
source /etc/profile

# ---- clean binary packages

sudo emaint binhost --fix
sudo eclean packages

# ---- clean and export distfiles

sudo eclean-dist
sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/distfiles/* $sf_vagrant/distfiles/

# ---- reset configs

sudo bash -c "sed -i '/^MAKEOPTS/d' /etc/portage/make.conf"           # delete MAKEOPTS (make.conf)
sudo bash -c "sed -i 's/^\(MAKEOPTS.*\)/#\1/g' /etc/genkernel.conf"   # comment-in MAKEOPTS (genkernel)

sudo find /etc/ -name '._cfg*'        # DEBUG: list all config files needing an update
sudo find /etc/ -name '._cfg*' -print -exec cat -n '{}' \;  # DEBUG: cat all config files needing an update

#sudo etc-update --verbose --preen     # auto-merge trivial changes

# ---- prevent replacement of our modified configs

sudo rm -f /etc/._cfg0000_boot.conf
sudo rm -f /etc/._cfg0000_genkernel.conf
sudo rm -f /etc/._cfg0000_updatedb.conf
sudo rm -f /etc/ssh/._cfg0000_sshd_config
sudo rm -f /etc/conf.d/._cfg0000_hostname

sudo etc-update --verbose --preen    # auto-merge trivial changes

sudo find /etc/ -name '._cfg*'        # DEBUG: list all remaining config files needing an update
sudo find /etc/ -name '._cfg*' -print -exec cat -n '{}' \;  # DEBUG: cat all config files needing an update

sudo etc-update --verbose --automode -5   # force 'auto-merge' for remaining configs

# ---- kernel

sudo eselect kernel list
sudo eclean-kernel -l
sudo ego boot update

# ---- eix

sudo eix-update
sudo eix-test-obsolete

# ---- remove resolv.conf

sudo rm -f /etc/resolv.conf
sudo rm -f /etc/resolv.conf.bak

# ---- system infos

sudo rc-update -v    # show final runlevels
sudo genlop -u -l    # show (un)merged packages before logs are cleared

# ---- mrproper

sudo /usr/local/sbin/foo-cleanup

# ---- claim some free space before box export

sudo bash -c 'dd if=/dev/zero of=/EMPTY bs=1M 2>/dev/null' || true
sudo rm -f /EMPTY

# --- clean bash history 

bash -c 'cat /dev/null > ~/.bash_history && history -c && exit'
