#!/bin/bash -ue
# vim: ts=4 sw=4 et

# get the lastest version number for a parent box from Vagrant Cloud
# see: https://www.vagrantup.com/docs/vagrant-cloud/api.html#boxes

# TODO cover with cloud_version.sh?

source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"

if [ -z ${BUILD_BOX_NAME:-} ]; then
    source "${BUILD_BIN_CONFIG:-./bin/config.sh}" quiet
fi

if [ -z "${BUILD_PARENT_BOX_CLOUD_VERSION:-}" ]; then
    if [ ! -z ${BUILD_PARENT_BOX_CHECK:-} ]; then
        require_commands curl jq
        step "Requesting parent box info ..."
        PARENT_VERSION_HTTP_CODE=$( \
          curl -sS -w "%{http_code}" -o /dev/null \
          https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_CLOUD_NAME \
        )
        case "$PARENT_VERSION_HTTP_CODE" in
            200) step `printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Parent box exists, will continue ...\n"`
                 ;;
            404) error `printf "Received HTTP $PARENT_VERSION_HTTP_CODE (file not found) ==> There is no parent box, please build and upload the parent box first.\n"` ;
                 exit 1
                 ;;
            *)   error `printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Unhandled status code while trying to get parent box meta info, aborting.\n"`
                 exit 1
                 ;;
        esac
        step "Getting latest version of parent box ..."
        LATEST_PARENT_VERSION=$( \
          curl -sS \
          https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_CLOUD_NAME \
        )
        export BUILD_PARENT_BOX_CLOUD_VERSION=$(echo $LATEST_PARENT_VERSION | jq .current_version.version | tr -d '"')
        if_not_silent result "Parent version is '$BUILD_PARENT_BOX_CLOUD_VERSION'"
    fi
else
    step "Reusing previous found parent box version: '$BUILD_PARENT_BOX_CLOUD_VERSION'"
fi
