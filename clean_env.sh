#!/bin/bash -ue

VBOXMACHINEFOLDER="~/.VirtualBox/Machines"

VBOXMANAGE=VBoxManage
command -v $VBOXMANAGE >/dev/null 2>&1 || VBOXMANAGE=vboxmanage   # try alternative

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }
command -v $VBOXMANAGE >/dev/null 2>&1 || { echo "Command '$VBOXMANAGE' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh quiet

echo "------------------------------------------------------------------------------"
echo "  ENVIRONMENT CLEANUP"
echo "------------------------------------------------------------------------------"

# do some more system cleanup:
# => suspend all VMs as seen by the current user
# => delete temporary files as seen by the current user
echo ">>> Suspend any running Vagrant VMs ..."
vagrant global-status | awk '/running/{print $1}' | xargs -r -d '\n' -n 1 -- vagrant suspend
echo ">>> Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
echo ">>> Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/*
echo ">>> Forcibly shutdown any running VirtualBox VMs ..."
$VBOXMANAGE list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$VBOXMANAGE controlvm "$1" acpipowerbutton\0"}' | xargs -0 >/dev/null
$VBOXMANAGE list runningvms | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$VBOXMANAGE controlvm "$1" poweroff\0"}' | xargs -0 >/dev/null
echo ">>> Delete all inaccessible VMs ..."
$VBOXMANAGE list vms | grep "<inaccessible>" | sed -r 's/.*\{(.*)\}/\1/' | awk '{print "$VBOXMANAGE unregistervm --delete "$1"\0"}' | xargs -0 >/dev/null
echo ">>> Force remove of appliance from VirtualBox machine folder ..."
# FIXME assumed path ~/.VirtualBox/Machines/ might be incorrect, better get this from VirtualBox config somehow
rm -rf $VBOXMACHINEFOLDER/$BUILD_BOX_NAME/ || true
echo ">>> Drop build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
