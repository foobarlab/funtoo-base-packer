#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# add bash-completion
sudo emerge -vt app-shells/bash-completion

# add zsh 
sudo emerge -vt app-shells/zsh app-shells/zsh-completions app-doc/zsh-lovers

cat <<'DATA' | sudo tee -a /root/.zshrc
# zsh config for root user:

# add /usr/local paths
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
DATA

# add dash
sudo emerge -vt app-shells/dash

# add a logging facility
sudo emerge -vt app-admin/rsyslog
sudo rc-update add rsyslog default

# add a cron service
sudo emerge -vt sys-process/vixie-cron
sudo rc-update add vixie-cron default

# add some entropy and randomness
sudo emerge -vt sys-apps/haveged
sudo rc-update add haveged default

# install vim and configure as default editor
sudo emerge -vt app-editors/vim
sudo eselect editor set vi
sudo eselect visual set vi
sudo eselect vi set vim
# add vim to rc files
cat <<'DATA' | sudo tee -a /root/.bashrc

export EDITOR=/usr/bin/vim    # default editor

DATA
cat <<'DATA' | sudo tee -a /root/.zshrc

export EDITOR=/usr/bin/vim    # default editor

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.bashrc

export EDITOR=/usr/bin/vim    # default editor

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.zshrc

export EDITOR=/usr/bin/vim    # default editor

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
cat <<'DATA' | sudo tee -a /root/.zshrc
# restart mc with last used folder
. /usr/libexec/mc/mc.sh

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.bashrc
# restart mc with last used folder
. /usr/libexec/mc/mc.sh

DATA
cat <<'DATA' | sudo tee -a ~vagrant/.zshrc
# restart mc with last used folder
. /usr/libexec/mc/mc.sh

DATA

# various utils
sudo emerge -vt \
	sys-apps/pv \
	sys-process/htop \
	dev-python/py-cpuinfo \
	dev-python/scandir \
	dev-python/netifaces \
	sys-apps/hdparm \
	sys-process/lsof \
	sys-fs/ncdu \
	sys-apps/mlocate \
	app-text/tree \
	sys-apps/progress \
	app-misc/screen \
	app-misc/tmux \
	www-client/links \
	net-ftp/ncftp \
	mail-client/mutt \
	app-portage/eix \
	app-portage/genlop \
	app-portage/cpuid2cpuflags \
	app-misc/ranger \
	sys-apps/most

# nice console font (https://www.funtoo.org/Fonts)
sudo emerge -vt media-fonts/terminus-font
BUILD_FONT="ter-116b"
export BUILD_FONT
sudo sed -i 's/consolefont=\"default8x16\"/consolefont=\"'$BUILD_FONT'\"/g' /etc/conf.d/consolefont
sudo rc-update add consolefont boot

# verbose 'local.d' service
cat <<'DATA' | sudo tee -a /etc/conf.d/local
rc_verbose=yes
DATA
