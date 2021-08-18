#!/bin/bash -ue
# vim: ts=4 sw=4 et

# get the lastest version number for a parent box from Vagrant Cloud
# see: https://www.vagrantup.com/docs/vagrant-cloud/api.html#boxes

# imports
. ./lib/functions.sh

if [ -z ${BUILD_BOX_NAME:-} ]; then
    error "This script is for internal use and can not be called directly! Aborting."
    exit 1
fi

# TODO run only once?

if [ ! -z ${BUILD_PARENT_BOX_CHECK:-} ]; then
    require_commands curl jq
    . vagrant_cloud_token.sh
    highlight "Reading meta info of parent box ..."

    PARENT_VERSION_HTTP_CODE=$( \
    curl -sS -w "%{http_code}" -o /dev/null \
      --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
      https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_CLOUD_NAME \
    )
    case "$PARENT_VERSION_HTTP_CODE" in
        200) info `printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Parent box exists, will continue ...\n"` ;;
        404) error `printf "Received HTTP $PARENT_VERSION_HTTP_CODE (file not found) ==> There is no parent box, please build and upload the parent box first.\n"` ; exit 1 ;;
        *) error `printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Unhandled status code while trying to get parent box meta info, aborting.\n"` ; exit 1 ;;
    esac

    highlight "Getting latest version of parent box ..."
    LATEST_PARENT_VERSION=$( \
    curl -sS \
      --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
      https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_CLOUD_NAME \
    )

    export BUILD_PARENT_BOX_CLOUD_VERSION=$(echo $LATEST_PARENT_VERSION | jq .current_version.version | tr -d '"')
    info "Found parent box version: '$BUILD_PARENT_BOX_CLOUD_VERSION'"
fi
