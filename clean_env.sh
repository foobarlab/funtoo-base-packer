#!/bin/bash -ue
# vim: ts=4 sw=4 et

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

title "ENVIRONMENT CLEANUP"

highlight "Housekeeping Vagrant environment ..."
step "Prune old parent versions of box '${BUILD_PARENT_BOX_NAME}' ..."
vagrant box prune -f -k --name ${BUILD_PARENT_BOX_NAME}
step "Prune previous versions of box '${BUILD_BOX_NAME}' ..."
vagrant box prune -f -k --name ${BUILD_BOX_NAME}
step "Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
step "Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/* || true

highlight "Housekeeping VirtualBox environment ..."
step "Forcibly shutdown any running VirtualBox machine named '$BUILD_BOX_NAME' ..."
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
step "Searching for inaccessible machines named '$BUILD_BOX_NAME' ..."
vbox_inaccessible_ids=$( $vboxmanage list vms | grep "<inaccessible>" | grep "$BUILD_BOX_NAME" | sed -r 's/.*\{(.*)\}/\1/' )
if [[ -z "$vbox_inaccessible_ids" || "$vbox_inaccessible_ids" = "" ]]; then
    info "No inaccessible machines named '$BUILD_BOX_NAME' found."
else
    for vbox_id in $vbox_inaccessible_ids; do
        warn "Deleting inaccessible machine '$BUILD_BOX_NAME' with UUID { $vbox_id }"
        $vboxmanage unregistervm --delete "$vbox_id" >/dev/null 2>&1 || true
    done
fi
step "Searching for any leftover inaccessible machines ..."
vbox_inaccessible_ids=$( $vboxmanage  list vms | grep "<inaccessible>" | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_inaccessible_ids" || "$vbox_inaccessible_ids" = "" ]]; then
    info "No leftover inaccessible machines found."
else
    for vbox_id in $vbox_inaccessible_ids; do
        warn "Deleting leftover inaccessible machine with UUID { $vbox_id }"
        $vboxmanage unregistervm --delete "$vbox_id" >/dev/null 2>&1 || true
    done
fi
step "Force removing of appliance from VirtualBox machine folder ..."
vboxmachinefolder=$( $vboxmanage list systemproperties | grep "Default machine folder" | cut -d ':' -f2 | sed -e 's/^\s*//g' )
rm -rf "$vboxmachinefolder/$BUILD_BOX_NAME/" || true

step "Checking VirtualBox hdds ..."
vbox_hdd_found_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
#$vboxmanage list hdds
info "Total $vbox_hdd_found_count hdd(s) found."

# FIXME if $vbox_hdd_found_count is zero skip hdd check ...

step "Collecting VirtualBox hdd data ..."
declare -a vbox_hdd_uuids=( $( $vboxmanage list hdds | grep -o "^UUID:.*" | sed -e "s/^UUID: //g" ) )
vbox_hdd_locations=$( $vboxmanage list hdds | grep -o "^Location:.*" | sed -e "s/^Location:[[:space:]]*//g" | sed -e "s/\ /\\\ /g" ) #| sed -e "s/^/\"/g" | sed -e "s/$/\"/g"  )
eval "declare -a vbox_hdd_locations2=($(echo "$vbox_hdd_locations" ))"
declare -a vbox_hdd_states=( $( $vboxmanage list hdds | grep -o "^State:.*" | sed -e "s/^State: //g" ) )

for (( i=0; i<$vbox_hdd_found_count; i++ )); do
    if [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VMDK" ]]; then
        info "Found '$BUILD_PARENT_BOX_CLOUD_VMDK'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            step "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            step "Removing hdd image file ..."
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            info "Media accessible, keeping hdd image."
        fi
    elif [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
        info "Found '$BUILD_PARENT_BOX_CLOUD_VDI'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            step "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            step "Removing hdd image file ..."
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            info "Media accessible, keeping hdd image."
        fi
    elif [[ "${vbox_hdd_locations2[$i]}" = "$HOME/VirtualBox VMs/${BUILD_BOX_NAME}/box-disk001.vmdk" ]]; then
        info "Found '${vbox_hdd_locations2[$i]}'"
        if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            step "Removing hdd from Media Manager ..."
            $vboxmanage closemedium disk "${vbox_hdd_uuids[$i]}" --delete
            step "Removing hdd image file ..."
            rm -f "$vbox_hdd_locations2[$i]" || true
        else
            info "Media accessible, keeping hdd image."
        fi
    elif [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
        warn "Found inaccessible hdd: '${vbox_hdd_locations2[$i]}'"
        # TODO check if location is related to current or parent box
        #step "Removing hdd from Media Manager ..."
        #$vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
        #step "Removing hdd image file ..."
        #rm -f "$vbox_hdd_locations2[$i]" || true
    fi
done

highlight "Housekeeping sources ..."

step "Dropping build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
