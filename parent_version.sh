#!/bin/bash

# get the lastest version number for a parent box from Vagrant Cloud
# see: https://www.vagrantup.com/docs/vagrant-cloud/api.html#boxes

if [ -z ${BUILD_BOX_NAME:-} ]; then
	echo "This script is for internal use and can not be called directly! Aborting."
	exit 1
fi

if [ -z ${BUILD_PARENT_BOX_CHECK:-} ]; then

	echo "Skipping parent box check ..."

else

	command -v curl >/dev/null 2>&1 || { echo "Command 'curl' required but it's not installed.  Aborting." >&2; exit 1; }
	command -v jq >/dev/null 2>&1 || { echo "Command 'jq' required but it's not installed.  Aborting." >&2; exit 1; }
	
	. vagrant_cloud_token.sh
	
	echo "Reading meta info of parent box ..."
	
	PARENT_VERSION_HTTP_CODE=$( \
	curl -sS -w "%{http_code}" -o /dev/null \
	  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
	  https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_VAGRANTCLOUD_NAME \
	)
	
	case "$PARENT_VERSION_HTTP_CODE" in
		200) printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Parent box exists, will continue ...\n" ;;
	    404) printf "Received HTTP $PARENT_VERSION_HTTP_CODE (file not found) ==> There is no parent box, please build and upload the parent box first.\n" ; exit 1 ;;   
	    *) printf "Received: HTTP $PARENT_VERSION_HTTP_CODE ==> Unhandled status code while trying to get parent box meta info, aborting.\n" ; exit 1 ;;
	esac
	
	echo "Determine version of parent box ..."
	
	LATEST_PARENT_VERSION=$( \
	curl -sS \
	  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
	  https://app.vagrantup.com/api/v1/box/$BUILD_PARENT_BOX_VAGRANTCLOUD_NAME \
	)
	
	export BUILD_PARENT_BOX_VAGRANTCLOUD_VERSION=$(echo $LATEST_PARENT_VERSION | jq .current_version.version | tr -d '"')
	
	echo "Found latest parent version: $BUILD_PARENT_BOX_VAGRANTCLOUD_VERSION"

fi
