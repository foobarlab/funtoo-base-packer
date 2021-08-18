#!/bin/bash -ue
# vim: ts=4 sw=4 et

# this script will use an existing box version
# or generate a new box version in semantic
# versioning format: major.minor.buildnumber
# as required by Vagrant

. ./lib/functions.sh "$*"

if [ ! -f version ]; then
    error "Missing file 'version'! Please run './config.sh' for default major version numbering."
    exit 1
fi

if [ -z "${BUILD_BOX_VERSION:-}" ]; then
    if [ -f build_version ]; then
        BUILD_BOX_VERSION=$(<build_version)
    else
        # get major version (must exist as file 'version'):
        BUILD_MAJOR_VERSION=$(<version)
        # generate minor version (date in format YYMMDD):
        BUILD_MINOR_VERSION=$(date +%y%m%d)
        # take existing env var BUILD_NUMBER, increment the one stored in
        # file 'build_number' or initialize a new one beginning with 0:
        if [ -z ${BUILD_NUMBER:-} ] ; then
            if [ -f build_number ]; then
                # read from file and increase by one
                BUILD_NUMBER=$(<build_number)
                BUILD_NUMBER=$((BUILD_NUMBER+1))
            else
                BUILD_NUMBER=0
            fi
            # store for later reuse in file 'build_number'
            echo $BUILD_NUMBER > build_number
            export BUILD_NUMBER
        fi
        BUILD_BOX_VERSION=$BUILD_MAJOR_VERSION.$BUILD_MINOR_VERSION.$BUILD_NUMBER
    fi    
    export BUILD_BOX_VERSION
    echo $BUILD_BOX_VERSION > build_version
else
    : #if_not_silent info "Reusing previous set version: '$BUILD_BOX_VERSION'"
fi

if_not_silent result "Build version is '$BUILD_BOX_VERSION'"
