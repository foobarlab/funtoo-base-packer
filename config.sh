#!/bin/bash

export BUILD_BOX_NAME="funtoo-base"
export BUILD_BOX_USERNAME="foobarlab"

export BUILD_BOX_PROVIDER="virtualbox"

export BUILD_BOX_FUNTOO_VERSION="1.4"
export BUILD_BOX_SOURCES="https://github.com/foobarlab/funtoo-base-packer"

export BUILD_PARENT_BOX_NAME="funtoo-stage3"
export BUILD_PARENT_BOX_VAGRANTCLOUD_NAME="$BUILD_BOX_USERNAME/$BUILD_PARENT_BOX_NAME"

export BUILD_GUEST_TYPE="Gentoo_64"

# number of cores used during box creation (memory is calculated automatically):
export BUILD_CPUS="4"

# default memory/cpus used for final created box:
export BUILD_BOX_CPUS="2"
export BUILD_BOX_MEMORY="2048"

export BUILD_FLAVOR="server"              # specify the flavor profile, see https://www.funtoo.org/Funtoo_Profiles#Flavors
export BUILD_KERNEL=true                  # set to true to build a new kernel (Debian)
export BUILD_GCC_VERSION=""               # experimental: specify which GCC version to install or leave empty to keep the default, e.g. "9.1.1"
export BUILD_REBUILD_SYSTEM=false         # experimental: set to true when GCC version has changed
export BUILD_REPORT_SPECTRE=true          # if true, report Spectre/Meltdown vulunerability status
export BUILD_INCLUDE_ANSIBLE=true         # if true, include Ansible for automation
export BUILD_WINDOW_SYSTEM=true           # build X window system (X.Org)
export BUILD_HEADLESS=false               # if false, gui will be shown

export BUILD_KEEP_MAX_CLOUD_BOXES=1       # set the maximum number of boxes to keep in Vagrant Cloud

# ----------------------------! do not edit below this line !----------------------------

echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g' > version    # auto set major version
. version.sh    # determine build version

let "jobs = $BUILD_CPUS + 1"       # calculate number of jobs (threads + 1)
export BUILD_MAKEOPTS="-j${jobs}"
let "memory = $jobs * 2048"        # recommended 2GB for each job
export BUILD_MEMORY="${memory}"

BUILD_BOX_RELEASE_NOTES="Funtoo $BUILD_BOX_FUNTOO_VERSION (x86, generic 64-bit), Debian Kernel 5.8, VirtualBox Guest Additions 6.1"     # edit this to reflect actual setup

if [ -z ${BUILD_GCC_VERSION:-} ]; then
    BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, GCC 9.2"     # edit this to reflect actual setup
else
    BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, GCC ${BUILD_GCC_VERSION}"
fi

if [[ -n "$BUILD_WINDOW_SYSTEM" ]]; then
    if [ "$BUILD_WINDOW_SYSTEM" = true ]; then
        BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, X11 (Fluxbox)"     # edit this to reflect actual setup
    fi
fi

if [[ -n "$BUILD_INCLUDE_ANSIBLE" ]]; then
    if [ "$BUILD_INCLUDE_ANSIBLE" = true ]; then
        BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, Ansible 2.9"     # edit this to reflect actual setup
    fi
fi

export BUILD_BOX_RELEASE_NOTES

export BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME version $BUILD_BOX_VERSION"
if [ -z ${BUILD_TAG+x} ]; then
    # without build tag
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION"
else
    # with env var BUILD_TAG set
    # NOTE: for Jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION ($BUILD_TAG)"
fi
export BUILD_BOX_DESCRIPTION="$BUILD_BOX_RELEASE_NOTES<br><br>$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP<br><br>Source code: $BUILD_BOX_SOURCES"

export BUILD_OUTPUT_FILE="$BUILD_BOX_NAME-$BUILD_BOX_VERSION.box"
export BUILD_OUTPUT_FILE_TEMP="$BUILD_BOX_NAME.tmp.box"

# get the latest parent version from Vagrant Cloud API call:
. parent_version.sh

if [ $# -eq 0 ]; then
	echo "Executing $0 ..."
	echo "=== Build settings ============================================================="
	env | grep BUILD_ | sort
	echo "================================================================================"
fi
