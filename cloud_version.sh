#!/bin/bash -ue
# vim: ts=4 sw=4 et
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

CLOUD_VERSION_CURRENT='Current-version'
CLOUD_VERSION_FOUND='Found-version'

. config.sh quiet

require_commands curl jq

declare -A BUILD_CLOUD_VERSION

cloud_box_info=$( \
  curl -sS -f \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)
BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]=$(echo $cloud_box_info | jq .current_version.version | tr -d '"')
BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]=$(echo $cloud_box_info | jq .versions[] | jq .version | tr -d '"' | sort -r )

# iterate all found versions
for version in ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_FOUND]}; do
  step "Processing version '$version' ..."
  BUILD_CLOUD_VERSION["${version}"]=""
  
  # check if current
  if [[ $version = ${BUILD_CLOUD_VERSION[$CLOUD_VERSION_CURRENT]} ]]; then
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}is-current "
  fi
  
  # compare major version and check release kind
  major_version=$( echo $version | sed -e "s/[^0-9]*\([0-9]*\)[.].*/\1/" )
  case $major_version in
    "9999")
        BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}release-next "
      ;;
    *)
        BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}release-${major_version} "
      ;;
  esac

  # check if in scope
  if [ $major_version = $BUILD_BOX_MAJOR_VERSION ]; then
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}within-scope "
  else
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}out-of-scope "
  fi

  # collect box info
  cloud_box_info_item=$(echo $cloud_box_info | jq '.versions[] | select(.version=="'$version'")')
  #echo $cloud_box_info_item | jq

  # check if active
  cloud_box_info_item_status=$(echo $cloud_box_info_item | jq .status | tr -d '"')
  BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}status-${cloud_box_info_item_status} "

  # check if higher/lower than build version
  if [[ $BUILD_BOX_VERSION == $version ]]; then
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}equal-version "
  elif `version_lt $version $BUILD_BOX_VERSION`; then
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}lower-version "
  elif `version_lt $BUILD_BOX_VERSION $version`; then
    BUILD_CLOUD_VERSION[${version}]="${BUILD_CLOUD_VERSION[${version}]}higher-version "
  fi

done

# DEBUG
echo "==================================================================="
echo "DEBUG: Variable BUILD_CLOUD_VERSION (key: value):"
echo "==================================================================="
#echo "DEBUG: values -> ${BUILD_CLOUD_VERSION[@]}"   # values
#echo "DEBUG: keys -> ${!BUILD_CLOUD_VERSION[*]}"  # keys
for key in ${!BUILD_CLOUD_VERSION[*]}; do
  echo "${key//\-/ }: ${BUILD_CLOUD_VERSION[$key]}"
  #for value in ${BUILD_CLOUD_VERSION[$key]}; do
  #  echo "${key//\-/ }: $value"
  #done
done
