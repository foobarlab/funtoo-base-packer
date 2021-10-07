#!/bin/bash -ue
# vim: ts=4 sw=4 et

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

require_commands vagrant $vboxmanage

title "ENVIRONMENT CLEANUP"

highlight "Housekeeping Vagrant environment ..."
step "Prune old versions of parent box '${BUILD_PARENT_BOX_NAME}' ..."
vagrant box prune -f -k --name "${BUILD_PARENT_BOX_NAME}"
step "Prune previous versions of box '${BUILD_BOX_NAME}' ..."
vagrant box prune -f -k --name "${BUILD_BOX_NAME}"
step "Prune invalid Vagrant entries ..."
vagrant global-status --prune >/dev/null
step "Delete temporary Vagrant files ..."
rm -rf ~/.vagrant.d/tmp/* || true

highlight "Housekeeping VirtualBox environment ..."
step "Forcibly shutdown any running VirtualBox machine named '$BUILD_BOX_NAME' ..."
vbox_running_ids=$( $vboxmanage list runningvms | grep "\"$BUILD_BOX_NAME\"" | sed -r 's/.*\{(.*)\}/\1/' )
for vbox_id in $vbox_running_ids; do
    warn "ACPI shutdown '$vbox_id'"
    $vboxmanage controlvm "$vbox_id" acpipowerbutton >/dev/null 2>&1 || true
    warn "Poweroff '$vbox_id'"
    $vboxmanage controlvm "$vbox_id" poweroff >/dev/null 2>&1 || true
done

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
if [ $vbox_hdd_found_count -eq 0 ]; then
    info "No hdds found."
else
    declare -a vbox_hdd_uuids=( $( $vboxmanage list hdds | grep -o "^UUID:.*" | sed -e "s/^UUID: //g" ) )
    vbox_hdd_locations=$( $vboxmanage list hdds | grep -o "^Location:.*" | sed -e "s/^Location:[[:space:]]*//g" | sed -e "s/\ /\\\ /g" ) #| sed -e "s/^/\"/g" | sed -e "s/$/\"/g"  )
    eval "declare -a vbox_hdd_locations2=($(echo "$vbox_hdd_locations" ))"
    declare -a vbox_hdd_states=( $( $vboxmanage list hdds | grep -o "^State:.*" | sed -e "s/^State: //g" ) )
    for (( i=0; i<$vbox_hdd_found_count; i++ )); do
        if [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VMDK" ]]; then
            if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
                warn "Found inaccessible parent box hdd: '$BUILD_PARENT_BOX_CLOUD_VMDK'"
                result "Removing hdd from Media Manager ..."
                $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
                rm -f "$vbox_hdd_locations2[$i]" || true
            fi
        elif [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
            if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
                warn "Found inaccessible parent box clone hdd: '$BUILD_PARENT_BOX_CLOUD_VDI'"
                result "Removing hdd from Media Manager ..."
                $vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
                rm -f "$vbox_hdd_locations2[$i]" || true
            fi
        elif [[ "${vbox_hdd_locations2[$i]}" = "$HOME/VirtualBox VMs/${BUILD_BOX_NAME}/box-disk001.vmdk" ]]; then
            if [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
                warn "Found inaccessible build box hdd: '${vbox_hdd_locations2[$i]}'"
                result "Removing hdd from Media Manager ..."
                $vboxmanage closemedium disk "${vbox_hdd_uuids[$i]}" --delete
                rm -f "$vbox_hdd_locations2[$i]" || true
            fi
        elif [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            warn "Found another inaccessible hdd: '${vbox_hdd_locations2[$i]}'"
            # TODO check if location is related to current or parent box
            todo "Check if location is related to current or parent box, remove?"
            #step "Removing hdd from Media Manager ..."
            #$vboxmanage closemedium disk ${vbox_hdd_uuids[$i]} --delete
            #rm -f "$vbox_hdd_locations2[$i]" || true
        fi
    done
    sleep 1
    vbox_hdd_left_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
    info "Total $vbox_hdd_found_count hdd(s) processed. Keeping $vbox_hdd_left_count hdd(s)."
fi

step "Searching for VirtualBox named '$BUILD_BOX_NAME' ..."
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
    info "No machine named '$BUILD_BOX_NAME' found."
else
    warn "Found machine UUID for '$BUILD_BOX_NAME': { $vbox_machine_id }"
    result "Deleting machine '$BUILD_BOX_NAME' ..."
    $vboxmanage unregistervm --delete $vbox_machine_id >/dev/null 2>&1 || true
fi

highlight "Housekeeping sources ..."

step "Dropping build number ..."
rm -f build_number || true

# basic cleanup
echo
. clean.sh
