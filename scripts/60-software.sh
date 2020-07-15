#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# add a logging facility
sudo emerge -vt app-admin/rsyslog
sudo rc-update add rsyslog default

# install vim and configure as default editor
sudo emerge -vt app-editors/vim 
sudo eselect editor set vi
sudo eselect visual set vi
sudo eselect vi set vim
# add vim to .bashrc
cat <<'DATA' | sudo tee -a /root/.bashrc

# use vim as default editor
export EDITOR=/usr/bin/vim
DATA
cat <<'DATA' | sudo tee -a ~vagrant/.bashrc

# use vim as default editor
export EDITOR=/usr/bin/vim
DATA
# custom .vimrc
cat <<'DATA' | sudo tee -a /root/.vimrc
" default to no visible whitespace (was enabled in global /etc/vim/vimrc)
setlocal nolist noai

set foldmethod=indent       " automatically fold by indent level
set nofoldenable            " ... but have folds open by default

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.vimrc
" default to no visible whitespace (was enabled in global /etc/vim/vimrc)
setlocal nolist noai

set foldmethod=indent       " automatically fold by indent level
set nofoldenable            " ... but have folds open by default

DATA
# set correct owner for newly created .vimrc for 'vagrant' user
sudo chown vagrant:vagrant ~vagrant/.vimrc

# install Midnight Commander + custom setting
sudo emerge -vt app-misc/mc
cat <<'DATA' | sudo tee -a /root/.bashrc
# restart mc with last used folder
. /usr/libexec/mc/mc.sh

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.bashrc
# restart mc with last used folder
. /usr/libexec/mc/mc.sh

DATA

# commandline utils
sudo emerge -vt app-shells/bash-completion

# process utils
sudo emerge -vt sys-process/htop

# file utils
sudo emerge -vt sys-process/lsof sys-fs/ncdu sys-apps/mlocate

# terminal multiplexers
sudo emerge -vt app-misc/screen app-misc/tmux

# network related utils
sudo emerge -vt www-client/links net-ftp/ncftp mail-client/mutt

# funtoo/gentoo management
sudo emerge -vt app-portage/eix

# nice console font (https://www.funtoo.org/Fonts)
sudo emerge -vt media-fonts/terminus-font
#BUILD_FONT="ter-114n"
#BUILD_FONT="ter-i14n"
BUILD_FONT="ter-i14v"
export BUILD_FONT
sudo sed -i 's/consolefont=\"default8x16\"/consolefont=\"'$BUILD_FONT'\"/g' /etc/conf.d/consolefont
sudo rc-update add consolefont boot
