#!/bin/bash -ue
# vim: ts=4 sw=4 et

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
    result "Deleting machine ..."
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

step "Searching for forgotten VirtualBox HDD ..."

vbox_found_hdd_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
result "Found $vbox_found_hdd_count hdd(s)."

step "Collecting data ..."
declare -a vbox_hdd_uuids=( $( $vboxmanage list hdds | grep -o "^UUID:.*" | sed -e "s/^UUID: //g" ) )
vbox_hdd_locations=$( $vboxmanage list hdds | grep -o "^Location:.*" | sed -e "s/^Location:[[:space:]]*//g" | sed -e "s/\ /\\\ /g" ) #| sed -e "s/^/\"/g" | sed -e "s/$/\"/g"  )
eval "declare -a vbox_hdd_locations2=($(echo "$vbox_hdd_locations" ))"
declare -a vbox_hdd_states=( $( $vboxmanage list hdds | grep -o "^State:.*" | sed -e "s/^State: //g" ) )

for (( i=0; i<$vbox_found_hdd_count; i++ )); do
    if [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VMDK" ]]; then
        step "Found '$BUILD_PARENT_BOX_CLOUD_VMDK'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            highlight "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            highlight "Removing hdd image file"
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            result "Media accessible, keep hdd image."
        fi
    elif [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
        step "Found '$BUILD_PARENT_BOX_CLOUD_VDI'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            highlight "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            highlight "Removing hdd image file"
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            result "Media accessible, keep hdd image."
        fi
    elif [[ "${vbox_hdd_locations2[$i]}" = "$HOME/VirtualBox VMs/${BUILD_BOX_NAME}/box-disk001.vmdk" ]]; then
        step "Found '${vbox_hdd_locations2[$i]}'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            highlight "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            highlight "Removing hdd image file"
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            result "Media accessible, keep hdd image."
        fi
    fi
done

highlight "Housekeeping sources ..."

step "Dropping build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
