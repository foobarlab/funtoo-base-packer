#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

# configure zsh: install oh-my-zsh, see https://github.com/ohmyzsh/ohmyzsh
# TODO add 'ansible' plugin only if BUILD_INCLUDE_ANSIBLE is set and 'true'
cat <<'DATA' | sudo tee -a /etc/zsh/zshenv
export ZSH=/opt/oh-my-zsh    # use globally installed oh-my-zsh
export LANG=en_US.UTF-8
DATA
cat <<'DATA' | sudo tee -a /root/.zshrc
ZSH_THEME="clean"
DISABLE_AUTO_UPDATE="true"
ENABLE_CORRECTION="true"
plugins=(git ansible)
source $ZSH/oh-my-zsh.sh
DATA
cat <<'DATA' | sudo tee -a ~vagrant/.zshrc
ZSH_THEME="agnoster"
DISABLE_AUTO_UPDATE="true"
ENABLE_CORRECTION="true"
plugins=(git ansible)
source $ZSH/oh-my-zsh.sh
DATA
sudo chown vagrant:vagrant ~vagrant/.zshrc
cd /tmp
sudo wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
sudo chmod 755 ./install.sh
sudo ZSH="/opt/oh-my-zsh" ./install.sh --unattended --keep-zshrc

## sanitize perl packages
#sudo perl-cleaner --all
#
## remove any temp portage flags and update system
#for dir in /etc/portage/package.*; do
#  sudo rm -f /etc/portage/${dir##*/}/temp*
#done
#sudo emerge -vtuDN --with-bdeps=y --complete-graph=y @world

# net-mail/mailbase: adjust permissions as recommended during install
sudo chown root:mail /var/spool/mail/
sudo chmod 03775 /var/spool/mail/

# sys-apps/mlocate: add shared folder (usually '/vagrant') to /etc/updatedb.conf prune paths to avoid leaking shared files
sudo sed -i 's/PRUNEPATHS="/PRUNEPATHS="\/vagrant /g' /etc/updatedb.conf
