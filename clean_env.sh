#!/bin/bash -ue

VBOXMANAGE=VBoxManage

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }
# FIXME command may be written as 'VBoxManage' instead of 'vboxmanage'
command -v $VBOXMANAGE >/dev/null 2>&1 || { echo "Command '$VBOXMANAGE' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh

# do a local folder clean before
. clean.sh

# do some more system cleanup:
# => suspend all VMs as seen by the current user
# => delete temporary files as seen by the current user
echo "Suspend any running Vagrant VMs ..."
vagrant global-status | awk '/running/{print $1}' | xargs -r -d '\n' -n 1 -- vagrant suspend
echo "Prune invalid Vagrant entries ..."
vagrant global-status --prune
echo "Forcibly shutdown any running VirtualBox VMs ..."
$VBOXMANAGE list runningvms | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} VBoxManage controlvm {} acpipowerbutton && true
$VBOXMANAGE list runningvms | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} VBoxManage controlvm {} poweroff && true
echo "Delete all inaccessible VMs ..."
$VBOXMANAGE list vms | grep "<inaccessible>" | sed -r 's/.*\{(.*)\}/\1/' | xargs -L1 -I {} $VBOXMANAGE unregistervm --delete {}
echo "Force remove of appliance from VirtualBox folder ..."
# FIXME assumed path ~/.VirtualBox/Machines/ might be incorrect, better get this from VirtualBox config somehow
rm -rf ~/.VirtualBox/Machines/$BUILD_BOX_NAME/
echo "Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*
echo "Current Status for VirtualBox (if any): "
$VBOXMANAGE list vms
echo "Current Status for Vagrant (if any):"
vagrant global-status
echo "All done. You may now run './build.sh' to build a fresh box."
