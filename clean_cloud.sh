#!/bin/bash -ue
# vim: ts=4 sw=4 et
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

. config.sh quiet

title "CLEAN CLOUD"

. vagrant_cloud_token.sh

require_commands curl jq

echo
info "This script will remove outdated boxes from Vagrant Cloud."
echo
info "A maximum number of $BUILD_KEEP_MAX_CLOUD_BOXES boxes will be kept."
info "The current version will always be kept."
echo
info "User.......: '$BUILD_BOX_USERNAME'"
info "Box........: '$BUILD_BOX_NAME'"
info "Provider...: '$BUILD_BOX_PROVIDER'"
echo

CLOUD_BOX_INFO=$( \
curl -sS -f \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

LATEST_CLOUD_VERSION=$(echo $CLOUD_BOX_INFO | jq .current_version.version | tr -d '"')
if [ $LATEST_CLOUD_VERSION = "null" ]; then
    success "Successful request, but no boxes were found."
    result "Nothing to remove. Please upload a box first."
    echo
    exit 0
fi

highlight "Latest version (will always be kept):"
info "$LATEST_CLOUD_VERSION"

EXISTING_CLOUD_VERSIONS=$(echo $CLOUD_BOX_INFO | jq .versions[] | jq .version | tr -d '"' | sort -r )

if [ "$EXISTING_CLOUD_VERSIONS" = "$LATEST_CLOUD_VERSION" ]; then
    :
else
    echo
    highlight "Additional found versions:"
    while IFS= read -r line; do
        if [ "$line" = "$LATEST_CLOUD_VERSION" ]; then
            :
        else
            info "$line"
        fi
    done <<< "$EXISTING_CLOUD_VERSIONS"
fi

COUNT=0
for ITEM in $EXISTING_CLOUD_VERSIONS; do
    COUNT=$((COUNT+1))
done

if [ $COUNT -eq 0 ]; then
    final "No box found. Nothing todo."
    exit 0
fi
if [ $COUNT -eq 1 ]; then
    final "Found a single box. Nothing todo."
    exit 0
fi

echo
warn "Total ${COUNT} boxes found. Will keep no more than ${BUILD_KEEP_MAX_CLOUD_BOXES} box(es)."
echo
read -p "    Continue (Y/n)? " choice
case "$choice" in
  n|N ) echo
        warn "User cancelled."
        echo
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
            highlight "Skipping box version $ITEM (latest version will always be kept)."
        else
            warn "Found outdated box version $ITEM ..."

            # revoke that version:
            highlight "Revoking version $ITEM ..."
            CLOUD_BOX_REVOKE=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  --request PUT \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$ITEM/revoke \
)
            # delete that version:
            highlight "Delete version $ITEM ..."
            CLOUD_BOX_DELETE=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  --request DELETE \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$ITEM \
)
            result "Deleted."
        fi
    else
        if [ "$ITEM" = "$LATEST_CLOUD_VERSION" ]; then
            highlight "Skipping box version $ITEM (latest version will always be kept) ..."
        else
            highlight "Skipping box version $ITEM ..."
        fi
    fi
done

# re-read box infos, show summary
CLOUD_BOX_INFO=$( \
curl -sS -f \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

EXISTING_CLOUD_VERSIONS=$(echo $CLOUD_BOX_INFO | jq .versions[] | jq .version | tr -d '"' | sort -r)
echo
highlight "Remaining box versions:"
info "$EXISTING_CLOUD_VERSIONS"
echo
