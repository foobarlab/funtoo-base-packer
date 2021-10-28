#!/bin/bash -ue
# vim: ts=4 sw=4 et

# this script will use an existing box version
# or generate a new box version in semantic
# versioning format: major.minor.buildnumber
# as required by Vagrant

source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"

if [ ! -f "${BUILD_FILE_VERSIONFILE}" ]; then
    error "Missing file '${BUILD_FILE_VERSIONFILE}'! Please run 'make config' for default major version numbering."
    exit 1
fi

if [ -z "${BUILD_BOX_VERSION:-}" ]; then
    if [ -f "$BUILD_FILE_BUILD_VERSION" ]; then
        BUILD_BOX_VERSION=$(<"$BUILD_FILE_BUILD_VERSION")
    else
        # get major version (must exist as file 'version'):
        BUILD_MAJOR_VERSION=$(<"${BUILD_FILE_VERSIONFILE}")
        # generate minor version (date in format YYMMDD):
        BUILD_MINOR_VERSION=$(date +%y%m%d)
        # take existing env var BUILD_NUMBER, increment the one stored in
        # file 'build_number' or initialize a new one starting with 0:
        if [ -z ${BUILD_NUMBER:-} ] ; then
            if [ -f "$BUILD_FILE_BUILD_NUMBER" ]; then
                # read from file and increase by one
                BUILD_NUMBER=$(<"$BUILD_FILE_BUILD_NUMBER")
                BUILD_NUMBER=$((BUILD_NUMBER+1))
            else
                BUILD_NUMBER=0
            fi
            # create build dir if not existant
            mkdir -p "${BUILD_DIR_BUILD}" || true
            # store 'build_number' for later reuse
            echo $BUILD_NUMBER > "${BUILD_FILE_BUILD_NUMBER}"
            export BUILD_NUMBER
        fi
        BUILD_BOX_VERSION=$BUILD_MAJOR_VERSION.$BUILD_MINOR_VERSION.$BUILD_NUMBER
    fi
    export BUILD_BOX_VERSION
    echo $BUILD_BOX_VERSION > "$BUILD_FILE_BUILD_VERSION"
else
    step "Reusing previous set version: '$BUILD_BOX_VERSION'"
fi

if_not_silent result "Build version is '$BUILD_BOX_VERSION'"
