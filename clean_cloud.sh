#!/bin/bash -e
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

. config.sh
. vagrant_cloud_token.sh

command -v curl >/dev/null 2>&1 || { echo "Command 'curl' required but it's not installed.  Aborting." >&2; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "Command 'jq' required but it's not installed.  Aborting." >&2; exit 1; }

echo "This script is marked as EXPERIMENTAL! Use at your own risk."
echo "This script will remove outdated boxes from Vagrant Cloud."
echo
echo "A maximum number of $BUILD_KEEP_MAX_CLOUD_BOXES boxes will be kept."
echo "The current version will always be kept."
echo
echo "User:     $BUILD_BOX_USERNAME"
echo "Box:      $BUILD_BOX_NAME"
echo "Provider: $BUILD_BOX_PROVIDER"

CLOUD_BOX_INFO=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

# FIXME: handle curl exit code
#echo "curl exit code: $?"

LATEST_CLOUD_VERSION=$(echo $CLOUD_BOX_INFO | jq .current_version.version | tr -d '"')
echo
echo "Current version (will always be kept):"
echo "$LATEST_CLOUD_VERSION"

EXISTING_CLOUD_VERSIONS=$(echo $CLOUD_BOX_INFO | jq .versions[] | jq .version | tr -d '"' | sort -r)
echo
echo "All found versions:"
echo "$EXISTING_CLOUD_VERSIONS"
echo

read -p "Continue (Y/n)? " choice
case "$choice" in 
  n|N ) echo "User cancelled."
  		exit 0
        ;;
  * ) echo
  		;;
esac

IFS=$'\n'
COUNT=0
for ITEM in $EXISTING_CLOUD_VERSIONS
do
	COUNT=$((COUNT+1))
	if [ $COUNT -gt $BUILD_KEEP_MAX_CLOUD_BOXES ]; then
		if [ "$ITEM" = "$LATEST_CLOUD_VERSION" ]; then
			echo "Skipping box version $ITEM (latest version will always be kept)."
		else
			echo "Found outdated box version $ITEM ..."
					
			# revoke that version:
			echo "Revoking version $ITEM ..."
			CLOUD_BOX_REVOKE=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  --request PUT \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$ITEM/revoke \
)
			# delete that version:
			echo "Delete version $ITEM ..."
			CLOUD_BOX_DELETE=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  --request DELETE \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$ITEM \
)
			echo "Done."			
		fi
	else
		if [ "$ITEM" = "$LATEST_CLOUD_VERSION" ]; then
			echo "Skipping box version $ITEM (latest version will always be kept) ..."
		else
			echo "Skipping box version $ITEM ..."
		fi
	fi
done

# re-read box infos, show summary
CLOUD_BOX_INFO=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

# FIXME: handle curl exit code
#echo "curl exit code: $?"

EXISTING_CLOUD_VERSIONS=$(echo $CLOUD_BOX_INFO | jq .versions[] | jq .version | tr -d '"' | sort -r)
echo
echo "Remaining box versions:"
echo "$EXISTING_CLOUD_VERSIONS"
echo
