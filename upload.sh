#!/bin/bash -e
# NOTE: Vagrant Cloud API see: https://www.vagrantup.com/docs/vagrant-cloud/api.html

. config.sh quiet

title "UPLOAD BOX"
if [ -f "$BUILD_OUTPUT_FILE" ]; then
	result "Found box file '$BUILD_OUTPUT_FILE' in the current directory."
else
	error "There is no box file '$BUILD_OUTPUT_FILE' in the current directory. Please run './build.sh' to build a box."
	if [ $# -eq 0 ]; then
		exit 1	# exit with error when running without param
	else
		exit 0	# silently exit when running with param
	fi 
fi

require_commands curl jq sha1sum pv

echo "This script will upload the current build box to Vagrant Cloud."
echo
echo "User:       $BUILD_BOX_USERNAME"
echo "Box:        $BUILD_BOX_NAME"
echo "Provider:   $BUILD_BOX_PROVIDER"
echo "Version:    $BUILD_BOX_VERSION"
echo "File:       $BUILD_OUTPUT_FILE"
echo "Build time: $BUILD_RUNTIME"
# FIXME show and compare sha1 checksum?
echo
echo "Please verify if above information is correct."
echo

read -p "Continue (Y/n)? " choice
case "$choice" in 
  n|N ) echo "User cancelled."
  		exit 0
        ;;
  * ) echo
  		;;
esac

. vagrant_cloud_token.sh

# check if a latest version does exist
LATEST_VERSION_HTTP_CODE=$( \
  curl -sS -w "%{http_code}" -o /dev/null \
    --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
    https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

case "$LATEST_VERSION_HTTP_CODE" in
  200) printf "Received: HTTP $LATEST_VERSION_HTTP_CODE ==> One or more boxes found, will continue ...\n" ;;
  404) printf "Received HTTP $LATEST_VERSION_HTTP_CODE (file not found) ==> There is no current box.\n" ;;
  *) printf "Received: HTTP $LATEST_VERSION_HTTP_CODE ==> Unhandled status code while trying to get latest box meta info, aborting.\n" ; exit 1 ;;
esac

# check version match on cloud and abort if same
echo "Checking existing cloud version ..."
LATEST_CLOUD_VERSION=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME \
)

LATEST_CLOUD_VERSION=$(echo $LATEST_CLOUD_VERSION | jq .current_version.version | tr -d '"')
echo "Our version: $BUILD_BOX_VERSION"
echo "Latest cloud version: $LATEST_CLOUD_VERSION"

if [[ $BUILD_BOX_VERSION = $LATEST_CLOUD_VERSION ]]; then
  echo "Same version already exists."
else 
  echo "Looks like we got a new version to provide."
fi

# Create a new box
echo "Trying to create a new box '$BUILD_BOX_NAME' ..."
UPLOAD_CREATE_BOX=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/boxes \
  --data '{ "box": { "username": "'$BUILD_BOX_USERNAME'", "name": "'$BUILD_BOX_NAME'" } }' \
)

UPLOAD_CREATE_BOX_SUCCESS=`echo $UPLOAD_CREATE_BOX | jq '.success'`
if [ $UPLOAD_CREATE_BOX_SUCCESS == 'false' ]; then
	# we get an error if the box name already exists so we can most likely ignore that error silently
	UPLOAD_BOX_NAME_ALREADY_TAKEN=`echo $UPLOAD_CREATE_BOX | jq '.errors' | jq 'contains(["Type has already been taken"])'`
	if [ $UPLOAD_BOX_NAME_ALREADY_TAKEN == 'true' ]; then
		echo "OK, the box name '$BUILD_BOX_NAME' seems already taken. No need to create a new box name."
	else
		echo "Error response from API:"
		echo $UPLOAD_CREATE_BOX | jq '.errors'
		exit 1
	fi
else
	echo "OK, we created a new box named '$BUILD_BOX_NAME'."
	echo "Response from API:"
	echo $UPLOAD_CREATE_BOX | jq
fi

# Create a new version
echo "Trying to create a new version '$BUILD_BOX_VERSION' ..."
UPLOAD_NEW_VERSION=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/versions \
  --data '{ "version": { "version": "'$BUILD_BOX_VERSION'", "description": "'"$BUILD_BOX_DESCRIPTION"'" } }' \
)

UPLOAD_NEW_VERSION_SUCCESS=`echo $UPLOAD_NEW_VERSION | jq '.success'`
if [ $UPLOAD_NEW_VERSION_SUCCESS == 'false' ]; then
	# we get an error if the box version already exists so we can most likely ignore that error silently
	UPLOAD_BOX_VERSION_ALREADY_TAKEN=`echo $UPLOAD_NEW_VERSION | jq '.errors' | jq 'contains(["Version has already been taken"])'`
	if [ $UPLOAD_BOX_VERSION_ALREADY_TAKEN == 'true' ]; then
		echo "OK, the box version '$BUILD_BOX_VERSION' seems already taken. No need to create a new version."
	else
		echo "Error response from API:"
		echo $UPLOAD_NEW_VERSION | jq '.errors'
		exit 1
	fi
else
	echo "OK, we created a new version '$BUILD_BOX_VERSION'."
	echo "Response from API:"
	echo $UPLOAD_NEW_VERSION | jq
fi

# create hash checksum, supported values: md5, sha1, sha256, sha384 and sha512
echo "Creating checksum ..." 
UPLOAD_CHECKSUM_CALC=`pv $BUILD_OUTPUT_FILE | sha1sum`
UPLOAD_CHECKSUM=`echo $UPLOAD_CHECKSUM_CALC | cut -d " " -f1`
echo -e "\033[1A$BUILD_OUTPUT_FILE: SHA-1 [' $UPLOAD_CHECKSUM' ]                        " 

# Create a new provider
echo "Trying to create a new provider '$BUILD_BOX_PROVIDER' ..."
UPLOAD_NEW_PROVIDER=$( \
curl -sS \
  --header "Content-Type: application/json" \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/providers \
  --data '{ "provider": { "checksum": "'$UPLOAD_CHECKSUM'", "checksum_type": "sha1", "name": "'$BUILD_BOX_PROVIDER'" } }' \
)

UPLOAD_NEW_PROVIDER_SUCCESS=`echo $UPLOAD_NEW_PROVIDER | jq '.success'`
if [ $UPLOAD_NEW_PROVIDER_SUCCESS == 'false' ]; then
	# we get an error if the provider already exists so we can most likely ignore that error silently
	UPLOAD_PROVIDER_ALREADY_EXISTS=`echo $UPLOAD_NEW_PROVIDER | jq '.errors' | jq 'contains(["Metadata provider must be unique for version"])'`
	if [ $UPLOAD_PROVIDER_ALREADY_EXISTS == 'true' ]; then
		echo "OK, the provider '$BUILD_BOX_PROVIDER' seems already taken. No need to create a new provider."
    # Check if upload is needed
    UPLOAD_PROVIDER=$( \
      curl -sS \
        --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
          https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/provider/$BUILD_BOX_PROVIDER \
    )
    UPLOAD_PROVIDER_CHECKSUM_TYPE=`echo $UPLOAD_PROVIDER | jq ".checksum_type" | tr -d '"'`
    UPLOAD_PROVIDER_CHECKSUM=`echo $UPLOAD_PROVIDER | jq ".checksum" | tr -d '"'`
    if [ "$UPLOAD_PROVIDER_CHECKSUM_TYPE" == 'sha1' ]; then
      echo "Upstream checksum type matched."
      if [ "$UPLOAD_PROVIDER_CHECKSUM" == "$UPLOAD_CHECKSUM" ]; then
        echo "Checksum matched. The box seems already up-to-date."
        # FIXME ask to delete the provider? check if there is a hosted file ... download and compare checksums?
        
        # DEBUG:
        echo $UPLOAD_PROVIDER | jq
        
        # TODO make a head request => if 404 the file was not uploaded yet, if 200 then ???
        
        exit 0
        
      else
        echo "Checksum mismatch ..."
        echo "Local : '$UPLOAD_CHECKSUM'"
        echo "Remote: '$UPLOAD_PROVIDER_CHECKSUM'"
      fi
    else
      echo "Upstream checksum type '$UPLOAD_PROVIDER_CHECKSUM_TYPE' not recognized! Forcing upload ..."
    fi
  else
		echo "Error response from API:"
		echo $UPLOAD_NEW_PROVIDER | jq '.errors'
		exit 1
	fi
else
	echo "OK, provider did not exist yet, creating a new provider '$BUILD_BOX_PROVIDER' ..."
	echo "Response from API:"
	echo $UPLOAD_NEW_PROVIDER | jq
fi

# Prepare the provider for upload/get an upload URL
echo "Requesting upload url ..."
UPLOAD_PREPARE_UPLOADURL=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/provider/$BUILD_BOX_PROVIDER/upload/direct \
)

UPLOAD_PREPARE_UPLOADURL_SUCCESS=`echo $UPLOAD_PREPARE_UPLOADURL | jq '.success'`
if [ $UPLOAD_PREPARE_UPLOADURL_SUCCESS == 'false' ]; then
	echo "Error response from API:"
	echo $UPLOAD_PREPARE_UPLOADURL | jq '.errors'
	exit 1
else
	echo "OK, we received an upload url and finalize callback."
fi

# Extract the upload URL and finalize callback from the response
UPLOAD_URL=$(echo "$UPLOAD_PREPARE_UPLOADURL" | jq '.upload_path' | tr -d '"')
UPLOAD_FINALIZE_URL=$(echo "$UPLOAD_PREPARE_UPLOADURL" | jq '.callback' | tr -d '"')

# Perform the upload

# TODO check curl version for progress-meter support? external script?
#BUILD_CURL_VERSION=$(curl -V | cut -d' ' -f2 | head -n 1)

# FIXME try --progress-meter and fallback to --progress-bar (curl is less than 7.6.7.0)
UPLOAD_PROGRESS="--progress-bar"
if [ -t 1 ]; then
  echo "Uploading ..."
else
  echo "Not a terminal, disabling progress meter ..."
  # FIXME no-progress-meter: fallback to --silent if curl is less or equal version 7.67.0
  #UPLOAD_PROGRESS="--no-progress-meter"
  UPLOAD_PROGRESS="--silent"
  echo "Uploading ... This may take a while ..."
fi

curl -f $UPLOAD_URL \
     $UPLOAD_PROGRESS \
     --request PUT \
     --upload-file $BUILD_OUTPUT_FILE \
| tee /dev/null

echo "Upload ended with exit code $?."

# Finalize upload
echo "Finalizing upload ..."
UPLOAD_FINALIZE=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  --request PUT \
  $UPLOAD_FINALIZE_URL \
)

echo "Finalized with exit code $?."

# DEBUG:
echo "DEBUG: Finalize result: '$UPLOAD_FINALIZE'"

# Release the version
echo "Releasing box ..."
UPLOAD_RELEASE_BOX=$( \
curl -sS \
  --header "Authorization: Bearer $VAGRANT_CLOUD_TOKEN" \
  https://app.vagrantup.com/api/v1/box/$BUILD_BOX_USERNAME/$BUILD_BOX_NAME/version/$BUILD_BOX_VERSION/release \
  --request PUT \
)

echo "Final response from API:"
echo $UPLOAD_RELEASE_BOX | jq

echo "All done."
