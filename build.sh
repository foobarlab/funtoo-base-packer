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
vbox_machine_id=$( $vboxmanage list vms | grep $BUILD_BOX_NAME | grep -Eo '{[0-9a-f\-]+}' | sed -n 's/[{}]//p' || echo )
if [[ -z "$vbox_machine_id" || "$vbox_machine_id" = "" ]]; then
    info "No machine named '$BUILD_BOX_NAME' found."
else
    warn "The box '$BUILD_BOX_NAME' already exists!"
    info "Machine UUID: ["$vbox_machine_id"]"
    echo
    info "Either this box is still powered on or you have a previous build"
    info "VirtualBox machine lying around."
    echo
    error "Can not continue, please run './clean_env.sh' to shutdown and remove the box, then try again."
    exit 1
fi

highlight "Checking presence of parent box '$BUILD_PARENT_BOX_NAME' ..."
vbox_hdd_found=$( $vboxmanage list hdds | grep "$BUILD_PARENT_BOX_CLOUD_VDI" || echo )
if [ -f $BUILD_PARENT_BOX_OVF ] && [[ -z "$vbox_hdd_found" || "$vbox_hdd_found" = "" ]]; then
    error "The parent box '${BUILD_PARENT_BOX_CLOUD_NAME}-${BUILD_PARENT_BOX_CLOUD_VERSION}' was not installed by this script!"
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

. distfiles.sh quiet

# do not build an already existing release on vagrant cloud by default
if [ ! $# -eq 0 ]; then
    BUILD_SKIP_VERSION_CHECK=true
else
    BUILD_SKIP_VERSION_CHECK=false
fi

if [ "$BUILD_SKIP_VERSION_CHECK" = false ]; then

    # check version match on cloud and abort if same
    highlight "Comparing local and cloud version ..."
    # FIXME check if box already exists (should give us a 200 HTTP response, if not we will get a 404)
    latest_cloud_version=$( \
    curl -sS \
      https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
    )

    latest_cloud_version=$(echo $latest_cloud_version | jq .current_version.version | tr -d '"')
    echo
    info "Latest cloud version..: '${latest_cloud_version}'"
    info "This version..........: '${BUILD_BOX_VERSION}'"
    echo

    # TODO automatically generate initial build number?

    if [[ "$BUILD_BOX_VERSION" = "$latest_cloud_version" ]]; then
        error "An equal version number already exists, please run './clean.sh' to increment your build number and try again."
        todo "Automatically increase build number?"
        exit 1
    else
        version_too_small=`version_lt $BUILD_BOX_VERSION $latest_cloud_version && echo "true" || echo "false"`
        if [[ "$version_too_small" = "true" ]]; then
            warn "This version is smaller than the cloud version!"
            todo "Automatically increase build_number"
        fi
        result "Looks like we build an unreleased version."
    fi
else
    warn "Skipped cloud version check."
fi

# FIXME refactor clean parent vdi part (see clean_env)
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
                    error "Seems like the vdi file is in state 'locked' and can not be removed easily. Is the box still up and running?"
                    todo "Detect if box is running and try to forecefully poweroff "
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

highlight "Trying to clone parent box hdd ..."
if [ -f $BUILD_PARENT_BOX_CLOUD_VMDK ]; then
    if [ -f "$BUILD_PARENT_BOX_CLOUD_VDI" ]; then
        rm -f "$BUILD_PARENT_BOX_CLOUD_VDI" || true
    fi
    step "Cloning to vdi file ..."
    $vboxmanage clonemedium disk "$BUILD_PARENT_BOX_CLOUD_VMDK" "$BUILD_PARENT_BOX_CLOUD_VDI" --format VDI
    if [ -z ${BUILD_BOX_DISKSIZE:-} ]; then
        info "BUILD_BOX_DISKSIZE is unset, skipping disk resize ..."
        # TODO set flag for packer (use another provisioner) ?
    else
        step "Resizing vdi to $BUILD_BOX_DISKSIZE MB ..."
        $vboxmanage modifymedium disk "$BUILD_PARENT_BOX_CLOUD_VDI" --resize "$BUILD_BOX_DISKSIZE"
        # TODO set flag for packer (use another provisioner) ?
    fi
else
    error "Missing vmdk file to clone!"
    result "Please try again and select 'yes' on downloading the parent box file."
    exit 1
fi
sync

final "All preparations done."

. config.sh

export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"

if [ $PACKER_LOG ]; then
    info "Logging Packer output to '$PACKER_LOG_PATH' ..."
fi

step "Invoking Packer build configuration '$PWD/packer/virtualbox.json' ..."
packer validate "$PWD/packer/virtualbox.json"

# TODO use 'only' conditionals in packer json for distinct provisioner ?
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
    # TODO vboxmanage modifymedium disk --compact <path to vdi> ?
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
result "Build runtime was $hours hours $minutes minutes $seconds seconds."
