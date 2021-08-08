#!/bin/bash -ue

start=`date +%s`

echo "Executing $0 ..."

export BUILD_PARENT_BOX_CHECK=true

. config.sh quiet

require_commands vagrant packer wget

header "Building box '$BUILD_BOX_NAME'"

BUILD_PARENT_BOX_OVF="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_NAME/0/virtualbox/box.ovf"
BUILD_PARENT_BOX_CLOUD_PATHNAME=`echo "$BUILD_PARENT_BOX_CLOUD_NAME" | sed "s|/|-VAGRANTSLASH-|"`
BUILD_PARENT_BOX_CLOUD_OVF="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_CLOUD_PATHNAME/$BUILD_PARENT_BOX_CLOUD_VERSION/virtualbox/box.ovf"

if [ -f $BUILD_PARENT_BOX_OVF ]; then
	export BUILD_PARENT_OVF=$BUILD_PARENT_BOX_OVF
	warn "An existing local '$BUILD_PARENT_BOX_NAME' parent box was detected. Skipping download ..."
else
	export BUILD_PARENT_OVF=$BUILD_PARENT_BOX_CLOUD_OVF
	if [ -f $BUILD_PARENT_BOX_CLOUD_OVF ]; then
		echo
		warn "The '$BUILD_PARENT_BOX_CLOUD_NAME' parent box with version '$BUILD_PARENT_BOX_CLOUD_VERSION' has been previously downloaded."
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
    	exit 1
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

# TODO include version info from file (copy to scripts?)

. config.sh

mkdir -p packages || true
export PACKER_LOG_PATH="$PWD/packer.log"
export PACKER_LOG="1"
packer validate virtualbox.json
packer build -force -on-error=abort virtualbox.json

title "OPTIMIZING BOX SIZE"

if [ -f "$BUILD_OUTPUT_FILE_TEMP" ]; then
    step "Suspending any running instances ..."
    vagrant suspend
    step "Destroying current box ..."
    vagrant destroy -f || true
    step "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    step "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE_TEMP"
    step "Powerup and provision '$BUILD_BOX_NAME' ..."
    vagrant --provision up || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
    step "Halting '$BUILD_BOX_NAME' ..."
    vagrant halt
    # TODO vboxmanage modifymedium --compact <path to vdi>
    step "Exporting base box ..."
    # TODO package additional optional files with --include
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
echo "Total build runtime was $hours hours $minutes minutes $seconds seconds."
