#!/bin/bash -ue
# vim: ts=4 sw=4 et

start=`date +%s`
export BUILD_PARENT_BOX_CHECK=true

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet

header "Building box '$BUILD_BOX_NAME'"
require_commands vagrant packer wget $vboxmanage

highlight "Checking presence of box '$BUILD_BOX_NAME' ..."
#$vboxmanage list vms
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
    info "No machine named '$BUILD_BOX_NAME' found."
else
    error "Found machine UUID for '$BUILD_BOX_NAME': { $vbox_machine_id }"
    result "Please run './clean_env.sh' to remove the box and try again."
    exit 1
fi

highlight "Checking presence of parent box '$BUILD_PARENT_BOX_NAME' ..."
vbox_hdd_found=$( $vboxmanage list hdds | grep "$BUILD_PARENT_BOX_CLOUD_VDI" || echo )
if [ -f $BUILD_PARENT_BOX_OVF ] && [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
    error "The parent box '${BUILD_PARENT_BOX_CLOUD_NAME}-${BUILD_PARENT_BOX_CLOUD_VERSION}' is not installed by Vagrant!"
    result "Try './clean_env.sh' in the parent box build dir or remove parent box manually, then try again."
    todo "Remove parent box from system?"
    exit 1
fi

highlight "Downloading parent box if needed ..."
if [ -f "$BUILD_PARENT_BOX_OVF" ]; then
    export BUILD_PARENT_OVF="$BUILD_PARENT_BOX_OVF"
    warn "An existing local '$BUILD_PARENT_BOX_NAME' parent box was detected. Skipping download ..."
else
    export BUILD_PARENT_OVF="$BUILD_PARENT_BOX_CLOUD_OVF"
    if [ -f "$BUILD_PARENT_BOX_CLOUD_OVF" ]; then
        echo
        info "The '$BUILD_PARENT_BOX_CLOUD_NAME' parent box with version '$BUILD_PARENT_BOX_CLOUD_VERSION' has been previously downloaded."
        echo
        read -p "    Do you want to delete it and download again (y/N)? " choice
        case "$choice" in
          y|Y ) step "Deleting existing '$BUILD_PARENT_BOX_CLOUD_NAME' parent box ..."
                vagrant box remove "$BUILD_PARENT_BOX_CLOUD_NAME" --box-version "$BUILD_PARENT_BOX_CLOUD_VERSION"
          ;;
          * ) result "Will keep existing '$BUILD_PARENT_BOX_CLOUD_NAME' parent box.";;
        esac
    fi

    if [ -f "$BUILD_PARENT_BOX_CLOUD_OVF" ]; then
        step "'$BUILD_PARENT_BOX_CLOUD_NAME' box already present, no need for download."
    else
        step "Downloading '$BUILD_PARENT_BOX_CLOUD_NAME' box with version '$BUILD_PARENT_BOX_CLOUD_VERSION' ..."
        vagrant box add -f "$BUILD_PARENT_BOX_CLOUD_NAME" --box-version "$BUILD_PARENT_BOX_CLOUD_VERSION" --provider virtualbox
    fi
fi

highlight "Downloading default ssh keys ..."
if [ -d "keys" ]; then
    info "Ok, key dir exists."
else
    step "Creating key dir ..."
    mkdir -p keys
fi

if [ -f "keys/vagrant" ]; then
    info "Ok, private key exists."
else
    step "Downloading default private key ..."
    wget -c https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant -O keys/vagrant
    if [ $? -ne 0 ]; then
        error "Could not download the private key. Exit code from wget was $?."
        exit $?
    fi
fi

if [ -f "keys/vagrant.pub" ]; then
    info "Ok, public key exists."
else
    step "Downloading default public key ..."
    wget -c https://raw.githubusercontent.com/hashicorp/vagrant/master/keys/vagrant.pub -O keys/vagrant.pub
    if [ $? -ne 0 ]; then
        error "Could not download the public key. Exit code from wget was $?."
        exit 1
    fi
fi

highlight "Create packages dir ..."
mkdir -p packages || true

. distfiles.sh

highlight "Cleanup existing parent box vdi file ..."
vbox_hdd_found=$( $vboxmanage list hdds | grep "$BUILD_PARENT_BOX_CLOUD_VDI" || echo )
if [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
    info "No vdi file found for parent box '${BUILD_PARENT_BOX_CLOUD_NAME}-${BUILD_PARENT_BOX_CLOUD_VERSION}'"  
else
    step "Scanning VirtualBox hdds ..."
    vbox_hdd_found_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
    #$vboxmanage list hdds
    info "Total $vbox_hdd_found_count hdd(s) found."
    step "Collecting VirtualBox hdd data ..."
    declare -a vbox_hdd_uuids=( $( $vboxmanage list hdds | grep -o "^UUID:.*" | sed -e "s/^UUID: //g" ) )
    vbox_hdd_locations=$( $vboxmanage list hdds | grep -o "^Location:.*" | sed -e "s/^Location:[[:space:]]*//g" | sed -e "s/\ /\\\ /g" )
    eval "declare -a vbox_hdd_locations2=($(echo "$vbox_hdd_locations" ))"  # split string into array (preserving spaces in path)
    declare -a vbox_hdd_states=( $( $vboxmanage list hdds | grep -o "^State:.*" | sed -e "s/^State: //g" ) )
    for (( i=0; i<$vbox_hdd_found_count; i++ )); do
        if [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
            result "Found vdi file '$BUILD_PARENT_BOX_CLOUD_VDI'"
            case "${vbox_hdd_states[$i]}" in
                "created" )
                    info "State: 'created'. Will be removed."
                    ;;
                "inaccessible")
                    info "State: 'inaccessible'. Will be removed."
                    ;;
                "locked")
                    error "Seems like the vdi file is in state 'locked' and can not be removed. Is the box already up and running?"
                    result "Please run './clean_env.sh' and try again."
                    exit 1
                    ;;
                *)
                    error "Unknown state: '"${vbox_hdd_states[$i]}"'"
                    exit 1
                    ;;
            esac
            highlight "Trying to remove hdd from Media Manager ..."
            $vboxmanage closemedium disk "${vbox_hdd_uuids[$i]}" --delete || true
            highlight "Removing previous resized vdi file ..."
            rm -f "$BUILD_PARENT_BOX_CLOUD_VDI" || true
        elif [[ "${vbox_hdd_states[$i]}" = "inaccessible" ]]; then
            warn "Found inaccessible hdd: '${vbox_hdd_locations2[$i]}'"
            highlight "Trying to remove hdd from Media Manager ..."
            $vboxmanage closemedium disk "${vbox_hdd_uuids[$i]}" --delete || true
        fi
    done
fi

if [[ -f $BUILD_PARENT_BOX_CLOUD_VMDK ]] && [[ ! -f "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
    highlight "Cloning parent box hdd to vdi file ..."
    $vboxmanage clonehd "$BUILD_PARENT_BOX_CLOUD_VMDK" "$BUILD_PARENT_BOX_CLOUD_VDI" --format VDI
    if [ -z ${BUILD_BOX_DISKSIZE:-} ]; then
        result "BUILD_BOX_DISKSIZE is unset, skipping disk resize ..."
        # TODO set flag for packer (use another provisioner)
    else
        highlight "Resizing vdi to $BUILD_BOX_DISKSIZE MB ..."
        $vboxmanage modifyhd "$BUILD_PARENT_BOX_CLOUD_VDI" --resize "$BUILD_BOX_DISKSIZE"
        # TODO set flag for packer (use another provisioner)
    fi
else
    error "Unable to clone parent box to vdi file. Please run './clean_env.sh' and try again."
    exit 1
fi
sync

. config.sh

step "Invoking packer ..."
export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"
packer validate "$PWD/packer/virtualbox.json"
# TODO use 'only' conditionals in packer json for distinct provisioner
packer build -force -on-error=abort "$PWD/packer/virtualbox.json"

title "OPTIMIZING BOX SIZE"

if [ -f "$BUILD_OUTPUT_FILE_TEMP" ]; then
    step "Suspending any running instances ..."
    vagrant suspend
    step "Destroying current box ..."
    vagrant destroy -f || true
    step "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    step "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add -f --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE_TEMP"
    step "Powerup and provision '$BUILD_BOX_NAME' ..."
    vagrant --provision up || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
    step "Halting '$BUILD_BOX_NAME' ..."
    vagrant halt
    # TODO vboxmanage modifymedium --compact <path to vdi> ?
    step "Exporting base box to '$BUILD_OUTPUT_FILE' ..."
    # TODO package additional optional files with --include ?
    # TODO use configuration values inside template (BUILD_BOX_MEMORY, etc.)
    #vagrant package --vagrantfile "Vagrantfile.template" --output "$BUILD_OUTPUT_FILE"
    vagrant package --output "$BUILD_OUTPUT_FILE"
    step "Removing temporary box file ..."
    rm -f  "$BUILD_OUTPUT_FILE_TEMP"
    # FIXME create sha1 checksum? and save to file for later comparison (include in build description?)
else
    error "There is no box file '$BUILD_OUTPUT_FILE_TEMP' in the current directory."
    exit 1
fi

end=`date +%s`
runtime=$((end-start))
hours=$((runtime / 3600));
minutes=$(( (runtime % 3600) / 60 ));
seconds=$(( (runtime % 3600) % 60 ));
echo "$hours hours $minutes minutes $seconds seconds" >> build_time
result "Total build runtime was $hours hours $minutes minutes $seconds seconds."
