#!/bin/bash -ue
# vim: ts=4 sw=4 et

[[ -v BUILD_ROOT ]] || BUILD_ROOT="${PWD}"   # FIXME try to set correct path (e.g. when run from inside bin dir)
source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"
require_commands git nproc
set -a

# ----------------------------!  default settings below  !----------------------------

BUILD_BOX_PROVIDER="virtualbox"
BUILD_GUEST_TYPE="Gentoo_64"

BUILD_BOX_USERNAME="foobarlab"
BUILD_BOX_NAME="funtoo-base"
BUILD_BOX_SOURCES="https://github.com/foobarlab/funtoo-base-packer"

BUILD_PARENT_BOX_USERNAME="foobarlab"
BUILD_PARENT_BOX_NAME="funtoo-stage3"
BUILD_PARENT_BOX_CLOUD_NAME="$BUILD_PARENT_BOX_USERNAME/$BUILD_PARENT_BOX_NAME"

BUILD_BOX_FUNTOO_VERSION="1.4"

# default memory/cpus/disk used for final created box:
BUILD_BOX_CPUS="2"
BUILD_BOX_MEMORY="2048"
#BUILD_BOX_DISKSIZE="51200" # resize disk in MB, comment-in to keep exiting size

# add a custom overlay?
BUILD_CUSTOM_OVERLAY=true
BUILD_CUSTOM_OVERLAY_NAME="foobarlab"
BUILD_CUSTOM_OVERLAY_URL="https://github.com/foobarlab/foobarlab-overlay.git"
BUILD_CUSTOM_OVERLAY_BRANCH="main"   # set to 'development' for most current (or 'main' for more stable)

BUILD_KERNEL=true                  # set to true to build a new kernel (Debian)
BUILD_GCC_VERSION=""               # experimental: specify which GCC version to install or leave empty to keep the default, e.g. "9.1.1"
BUILD_REBUILD_SYSTEM=false         # experimental: set to true when build toolchain (GCC, binutils, etc) has changed
BUILD_REPORT_SPECTRE=true          # if true, report Spectre/Meltdown vulunerability status
BUILD_INCLUDE_ANSIBLE=true         # if true, include Ansible for automation
BUILD_WINDOW_SYSTEM=true           # build X window system (X.Org)
BUILD_HEADLESS=false               # if false, gui will be shown

BUILD_KEEP_MAX_CLOUD_BOXES=1       # set the maximum number of boxes to keep in Vagrant Cloud

# ----------------------------!  do not edit below this line  !----------------------------

echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g' > "$BUILD_FILE_VERSIONFILE"    # auto set major version
source "${BUILD_DIR_BIN}/version.sh" "$*"   # determine build version

# detect number of system cpus available (select half of cpus for best performance)
BUILD_CPUS=$((`nproc --all` / 2))
let "jobs = $BUILD_CPUS + 1"       # calculate number of jobs (threads + 1)
BUILD_MAKEOPTS="-j${jobs}"

# determine ram available (select min and max)
BUILD_MEMORY_MIN=4096 # we want at least 4G ram for our build
# calculate max memory (set to 1/2 of available memory)
BUILD_MEMORY_MAX=$(((`grep MemTotal /proc/meminfo | awk '{print $2}'` / 1024 / 1024 / 2 + 1 ) * 1024))
let "memory = $BUILD_CPUS * 1024"   # calculate 1G ram for each cpu
BUILD_MEMORY="${memory}"
BUILD_MEMORY=$(($BUILD_MEMORY < $BUILD_MEMORY_MIN ? $BUILD_MEMORY_MIN : $BUILD_MEMORY)) # lower limit (min)
BUILD_MEMORY=$(($BUILD_MEMORY > $BUILD_MEMORY_MAX ? $BUILD_MEMORY_MAX : $BUILD_MEMORY)) # upper limit (max)

BUILD_BOX_MAJOR_VERSION=`echo $BUILD_BOX_FUNTOO_VERSION | sed -e 's/\.//g'`

BUILD_BOX_RELEASE_NOTES="Funtoo $BUILD_BOX_FUNTOO_VERSION (x86, intel64-nehalem), Debian Kernel 5.10, VirtualBox Guest Additions 6.1"     # edit this to reflect actual setup

if [ -z ${BUILD_GCC_VERSION:-} ]; then
    BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, GCC 9.2"     # edit this to reflect actual setup
else
    BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, GCC ${BUILD_GCC_VERSION}"
fi

if [[ -n "$BUILD_WINDOW_SYSTEM" ]]; then
    if [ "$BUILD_WINDOW_SYSTEM" = true ]; then
        BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, X11 (Fluxbox)"   # edit this to reflect actual setup
    fi
fi

if [[ -n "$BUILD_INCLUDE_ANSIBLE" ]]; then
    if [ "$BUILD_INCLUDE_ANSIBLE" = true ]; then
        BUILD_BOX_RELEASE_NOTES="${BUILD_BOX_RELEASE_NOTES}, Ansible 2.9"     # edit this to reflect actual setup
    fi
fi

BUILD_TIMESTAMP="$(date --iso-8601=seconds)"

BUILD_BOX_DESCRIPTION="$BUILD_BOX_NAME version $BUILD_BOX_VERSION"
if [ ! -z ${BUILD_TAG+x} ]; then
    # NOTE: for Jenkins builds we got some additional information: BUILD_NUMBER, BUILD_ID, BUILD_DISPLAY_NAME, BUILD_TAG, BUILD_URL
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION ($BUILD_TAG)"
fi

if [[ -f ${BUILD_FILE_BUILD_TIME} && -s ${BUILD_FILE_BUILD_TIME} ]]; then
    BUILD_RUNTIME=`cat ${BUILD_FILE_BUILD_TIME}`
    BUILD_RUNTIME_FANCY="Total build runtime was $BUILD_RUNTIME."
else
    BUILD_RUNTIME="unknown"
    BUILD_RUNTIME_FANCY="Total build runtime was not logged."
fi

BUILD_BOX_DESCRIPTION="$BUILD_BOX_RELEASE_NOTES<br><br>$BUILD_BOX_DESCRIPTION<br>created @$BUILD_TIMESTAMP<br>"

# check if in git environment and collect git data (if any)
BUILD_GIT=$(echo `git rev-parse --is-inside-work-tree 2>/dev/null || echo "false"`)
if [ $BUILD_GIT == "true" ]; then
    BUILD_GIT_COMMIT_REPO=`git config --get remote.origin.url`
    BUILD_GIT_COMMIT_BRANCH=`git rev-parse --abbrev-ref HEAD`
    BUILD_GIT_COMMIT_ID=`git rev-parse HEAD`
    BUILD_GIT_COMMIT_ID_SHORT=`git rev-parse --short HEAD`
    BUILD_GIT_COMMIT_ID_HREF="${BUILD_BOX_SOURCES}/tree/${BUILD_GIT_COMMIT_ID}"
    BUILD_GIT_LOCAL_MODIFICATIONS=$(if [ "`git diff --shortstat`" == "" ]; then echo 'false'; else echo 'true'; fi)
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Git repository: $BUILD_GIT_COMMIT_REPO"
    if [ $BUILD_GIT_LOCAL_MODIFICATIONS == "true" ]; then
        BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is in an experimental work-in-progress state. Local modifications have not been committed to Git repository yet.<br>$BUILD_RUNTIME_FANCY"
    else
        BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is based on branch $BUILD_GIT_COMMIT_BRANCH (commit id <a href=\\\"$BUILD_GIT_COMMIT_ID_HREF\\\">$BUILD_GIT_COMMIT_ID_SHORT</a>).<br>$BUILD_RUNTIME_FANCY"
    fi
else
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>Origin source code: $BUILD_BOX_SOURCES"
    BUILD_BOX_DESCRIPTION="$BUILD_BOX_DESCRIPTION<br>This build is not version controlled yet.<br>$BUILD_RUNTIME_FANCY"
fi

BUILD_OUTPUT_FILE_TEMP="${BUILD_DIR_BUILD}/${BUILD_BOX_NAME}.tmp.box"
BUILD_OUTPUT_FILE="${BUILD_DIR_BUILD}/${BUILD_BOX_NAME}-${BUILD_BOX_VERSION}.box"

BUILD_PARENT_BOX_CHECK=true

# get the latest parent version from Vagrant Cloud API call:
source "${BUILD_DIR_BIN}/parent_version.sh" "$*"

BUILD_PARENT_BOX_OVF="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_NAME/0/virtualbox/box.ovf"
BUILD_PARENT_BOX_CLOUD_PATHNAME=`echo "$BUILD_PARENT_BOX_CLOUD_NAME" | sed "s|/|-VAGRANTSLASH-|"`
BUILD_PARENT_BOX_CLOUD_OVF="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_CLOUD_PATHNAME/$BUILD_PARENT_BOX_CLOUD_VERSION/virtualbox/box.ovf"
BUILD_PARENT_BOX_CLOUD_VMDK="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_CLOUD_PATHNAME/$BUILD_PARENT_BOX_CLOUD_VERSION/virtualbox/box-disk001.vmdk"
BUILD_PARENT_BOX_CLOUD_VDI="$HOME/.vagrant.d/boxes/$BUILD_PARENT_BOX_CLOUD_PATHNAME/$BUILD_PARENT_BOX_CLOUD_VERSION/virtualbox/box-disk001.vdi"

# override build settings? load build.conf ... 
[[ -f ""${BUILD_FILE_BUILDCONF}"" ]] && source "${BUILD_FILE_BUILDCONF}"

if [ $# -eq 0 ]; then
    title "BUILD SETTINGS"
    if [ "$ANSI" = "true" ]; then
        env | grep BUILD_ | sort | awk -F"=" '{ printf("'${white}${bold}'%.40s '${default}'%s\n",  $1 "'${dark_grey}'........................................'${default}'" , $2) }'
    else
      env | grep BUILD_ | sort | awk -F"=" '{ printf("%.40s %s\n",  $1 "........................................" , $2) }'
    fi
    title_divider
fi
