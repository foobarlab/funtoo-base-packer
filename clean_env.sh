#!/bin/bash -ue

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

title "ENVIRONMENT CLEANUP"

highlight "Housekeeping Vagrant environment ..."
step "Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
step "Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/* || true

highlight "Housekeeping VirtualBox environment ..."
step "Forcibly shutdown any running VirtualBox VM named '$BUILD_BOX_NAME' ..."
vbox_running_id=$( $vboxmanage list runningvms | grep "\"$BUILD_BOX_NAME\"" | sed -r 's/.*\{(.*)\}/\1/' )
$vboxmanage controlvm "$vbox_running_id" acpipowerbutton >/dev/null 2>&1 || true
$vboxmanage controlvm "$vbox_running_id" poweroff >/dev/null 2>&1 || true

step "Searching for VirtualBox named '$BUILD_BOX_NAME' ..."
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
  info "No machine named '$BUILD_BOX_NAME' found."
else
  warn "Found machine UUID for '$BUILD_BOX_NAME': { $vbox_machine_id }"
  step "Deleting machine ..."
  $vboxmanage unregistervm --delete $vbox_machine_id >/dev/null 2>&1 || true
fi
step "Delete all inaccessible VMs named '$BUILD_BOX_NAME' ..."
vbox_inaccessible_id=$( $vboxmanage list vms | grep "<inaccessible>" | grep "$BUILD_BOX_NAME" | sed -r 's/.*\{(.*)\}/\1/' )
if [[ -z "$vbox_inaccessible_id" || "$vbox_inaccessible_id" = "" ]]; then
  info "No inaccessible machine named '$BUILD_BOX_NAME' found."
else
  warn "Found inaccessible machine UUID for '$BUILD_BOX_NAME': { vbox_inaccessible_id }"
  $vboxmanage unregistervm --delete "$vbox_inaccessible_id" >/dev/null 2>&1 || true
fi
step "Force remove of appliance from VirtualBox machine folder ..."
vboxmachinefolder=$( $vboxmanage list systemproperties | grep "Default machine folder" | cut -d ':' -f2 | sed -e 's/^\s*//g' )
rm -rf "$vboxmachinefolder/$BUILD_BOX_NAME/" || true
# TODO check if this is needed:
step "Searching for forgotten VirtualBox HDDS named '${BUILD_BOX_NAME}.vdi' ..."
vbox_hdd_found=$( $vboxmanage list hdds | grep "${BUILD_BOX_NAME}.vdi" || echo )
if [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
  info "No HDDs named '${BUILD_BOX_NAME}.vdi' found."
else
  vbox_found_hdd_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
  warn "Found $vbox_found_hdd_count hdd(s)."
  todo "Searching for HDD UUID ..."
  # DEBUG:
  $vboxmanage list hdds
  #$vboxmanage list hdds | grep -on "^UUID.*"
  #$vboxmanage list hdds | grep -on "^State:.*"
  #$vboxmanage list hdds | grep -on "^Location:.*"
  todo "Removing HDD from Media Manager ..."
  #$vboxmanage closemedium disk $vbox_hdd_id --delete
fi

highlight "Housekeeping sources ..."

step "Dropping build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
