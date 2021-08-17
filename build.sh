#!/bin/bash -ue
# vim: ts=4 sw=4 et

start=`date +%s`
export BUILD_PARENT_BOX_CHECK=true

vboxmanage=VBoxManage
command -v $vboxmanage >/dev/null 2>&1 || vboxmanage=vboxmanage   # try alternative

. config.sh quiet
. distfiles.sh

require_commands vagrant packer wget $vboxmanage

header "Building box '$BUILD_BOX_NAME'"

if [ -f $BUILD_PARENT_BOX_OVF ]; then
    export BUILD_PARENT_OVF=$BUILD_PARENT_BOX_OVF
    warn "An existing local '$BUILD_PARENT_BOX_NAME' parent box was detected. Skipping download ..."
else
    export BUILD_PARENT_OVF=$BUILD_PARENT_BOX_CLOUD_OVF
    if [ -f $BUILD_PARENT_BOX_CLOUD_OVF ]; then
        echo
        info "The '$BUILD_PARENT_BOX_CLOUD_NAME' parent box with version '$BUILD_PARENT_BOX_CLOUD_VERSION' has been previously downloaded."
        echo
        read -p "    Do you want to delete it and download again (y/N)? " choice
        case "$choice" in
          y|Y ) step "Deleting existing '$BUILD_PARENT_BOX_CLOUD_NAME' parent box ..."
                vagrant box remove $BUILD_PARENT_BOX_CLOUD_NAME --box-version $BUILD_PARENT_BOX_CLOUD_VERSION
          ;;
          * ) result "Will keep existing '$BUILD_PARENT_BOX_CLOUD_NAME' parent box.";;
        esac
    fi

    if [ -f $BUILD_PARENT_BOX_CLOUD_OVF ]; then
        step "'$BUILD_PARENT_BOX_CLOUD_NAME' box already present, no need for download."
    else
        step "Downloading '$BUILD_PARENT_BOX_CLOUD_NAME' box with version '$BUILD_PARENT_BOX_CLOUD_VERSION' ..."
        vagrant box add -f $BUILD_PARENT_BOX_CLOUD_NAME --box-version $BUILD_PARENT_BOX_CLOUD_VERSION --provider virtualbox
    fi
fi

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

step "Create packages dir ..."
mkdir -p packages || true

# TODO check when not resizing disk: do not storageattach in virtualbox.json! use 'only' conditionals in packer json ...

step "Searching for vdi file ..."
vbox_hdd_found=$( $vboxmanage list hdds | grep "$BUILD_PARENT_BOX_CLOUD_VDI" || echo )
if [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
    result "No vdi file found."
else
    vbox_found_hdd_count=$( $vboxmanage list hdds | grep -o "^UUID" | wc -l )
    info "Found $vbox_found_hdd_count hdd(s)."
    step "Collecting data ..."
    declare -a vbox_hdd_uuids=( $( $vboxmanage list hdds | grep -o "^UUID:.*" | sed -e "s/^UUID: //g" ) )
    vbox_hdd_locations=$( $vboxmanage list hdds | grep -o "^Location:.*" | sed -e "s/^Location:[[:space:]]*//g" | sed -e "s/\ /\\\ /g" ) #| sed -e "s/^/\"/g" | sed -e "s/$/\"/g"  )
    eval "declare -a vbox_hdd_locations2=($(echo "$vbox_hdd_locations" ))"  # split string into array (preserving spaces in path)
    declare -a vbox_hdd_states=( $( $vboxmanage list hdds | grep -o "^State:.*" | sed -e "s/^State: //g" ) )
    for (( i=0; i<$vbox_found_hdd_count; i++ )); do
        if [[ "${vbox_hdd_locations2[$i]}" = "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
            result "Found '$BUILD_PARENT_BOX_CLOUD_VDI'"
            # FIXME check state?
            result "State: ${vbox_hdd_states[$i]}"
            #result "UUID: ${vbox_hdd_uuids[$i]}"
            highlight "Removing HDD from Media Manager ..."
            $vboxmanage closemedium disk "${vbox_hdd_uuids[$i]}" --delete
            highlight "Removing previous resized vdi file ..."
            rm -f "$BUILD_PARENT_BOX_CLOUD_VDI" || true
        fi
    done
fi

if [[ ! -f "$BUILD_PARENT_BOX_CLOUD_VDI" ]]; then
    highlight "Cloning parent box hdd to vdi file ..."
    $vboxmanage clonehd "$BUILD_PARENT_BOX_CLOUD_VMDK" "$BUILD_PARENT_BOX_CLOUD_VDI" --format VDI
    if [ -z ${BUILD_BOX_DISKSIZE:-} ]; then
        result "BUILD_BOX_DISKSIZE is unset, skipping disk resize ..."
        # TODO set flag for packer (use another provisioner)
    else
        highlight "Resizing vdi to $BUILD_BOX_DISKSIZE MB ..."
        $vboxmanage modifyhd "$BUILD_PARENT_BOX_CLOUD_VDI" --resize $BUILD_BOX_DISKSIZE
        # TODO set flag for packer (use another provisioner)
    fi
fi
sync

. config.sh

step "Invoking packer ..."
export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"
packer validate "$PWD/packer/virtualbox.json"
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
    step "Exporting base box ..."
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
