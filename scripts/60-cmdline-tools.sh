#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# add shells/shellutils
sudo emerge -nuvtND --with-bdeps=y \
	app-eselect/eselect-sh \
	app-shells/bash-completion \
	app-shells/zsh \
	app-shells/zsh-completions \
	app-doc/zsh-lovers

# custom .zshrc
cat <<'DATA' | sudo tee -a /root/.zshrc
# add /usr/local paths
export PATH=$PATH:/usr/local/bin:/usr/local/sbin
DATA
cat <<'DATA' | sudo tee -a ~vagrant/.zshrc
# add /usr/local paths
export PATH=$PATH:/usr/local/bin
DATA

# add a logging facility
sudo emerge -nuvtND --with-bdeps=y app-admin/rsyslog
sudo rc-update add rsyslog default

# add a cron service
sudo emerge -nuvtND --with-bdeps=y sys-process/vixie-cron
sudo rc-update add vixie-cron default

# add some entropy and randomness
sudo emerge -nuvtND --with-bdeps=y sys-apps/haveged
sudo rc-update add haveged default

# install vim and configure as default editor
sudo emerge -nuvtND --with-bdeps=y app-editors/vim
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
sudo emerge -nuvtND --with-bdeps=y app-misc/mc
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

# sshfs/fuse
sudo emerge -nuvtND --with-bdeps=y \
	sys-fs/fuse \
	net-fs/sshfs

# various cmdline utils
sudo emerge -nuvtND --with-bdeps=y \
	sys-apps/pv \
	sys-process/htop \
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
	net-irc/irssi \
	app-portage/eix \
	app-portage/genlop \
	app-portage/portage-utils \
	app-portage/gentoolkit \
	app-portage/cpuid2cpuflags \
	app-misc/resolve-march-native \
	app-misc/ranger \
	sys-apps/most \
	app-eselect/eselect-awk \
    sys-apps/gawk

# nice console font (https://www.funtoo.org/Fonts)
sudo emerge -nuvtND --with-bdeps=y media-fonts/terminus-font
BUILD_FONT="ter-116b"
export BUILD_FONT
sudo sed -i 's/consolefont=\"default8x16\"/consolefont=\"'$BUILD_FONT'\"/g' /etc/conf.d/consolefont
sudo rc-update add consolefont boot

# verbose 'local.d' service
cat <<'DATA' | sudo tee -a /etc/conf.d/local
rc_verbose=yes
DATA

# sync any guest packages to host (via shared folder)
sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/packages/* $sf_vagrant/packages/
