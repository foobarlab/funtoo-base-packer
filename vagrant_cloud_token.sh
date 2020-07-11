#!/bin/bash

if [ -f ./vagrant-cloud-token ]; then
	echo "Using previously stored auth token."
	VAGRANT_CLOUD_TOKEN=`cat ./vagrant-cloud-token`	
else
	echo "No auth token found."
	echo
	echo "We will do the upload via API on the behalf of your Vagrant Cloud"
	echo "account. For this we will use an auth token. Please keep this token"
	echo "in a secure place or delete it after upload."
	echo
	echo "Please enter your Vagrant Cloud credentials to proceed:"
	echo
	echo -n "Username: "
	read AUTH_USERNAME
	echo -n "Password: "
	read -s AUTH_PASSWORD
	echo
	echo
	
	# Request auth token
	UPLOAD_AUTH_REQUEST=$( \
	curl -sS \
	  --header "Content-Type: application/json" \
	  https://app.vagrantup.com/api/v1/authenticate \
	  --data '{"token": {"description": "Login from cURL"},"user": {"login": "'$AUTH_USERNAME'","password": "'$AUTH_PASSWORD'"}}' \
	)
	
	UPLOAD_AUTH_REQUEST_SUCCESS=`echo $UPLOAD_AUTH_REQUEST | jq '.success'`
	if [ $UPLOAD_AUTH_REQUEST_SUCCESS == 'false' ]; then
		echo "Request for auth token failed."
		echo "Response from API:"
		echo $UPLOAD_AUTH_REQUEST | jq
		echo "Please consult the error above and try again."
		exit 1
	fi
	
	VAGRANT_CLOUD_TOKEN=`echo $UPLOAD_AUTH_REQUEST | jq '.token' | tr -d '"'`
	
	echo "OK, we got authorized."
	
	read -p "Do you want to store the auth token for future use (y/N)? " choice
	case "$choice" in 
	  y|Y ) echo "Storing auth token ..."
	  		echo $VAGRANT_CLOUD_TOKEN > ./vagrant-cloud-token
	  		chmod 600 ./vagrant-cloud-token
	        ;;
	  * ) echo "Not storing auth token."
	      ;;
	esac
	
fi

export VAGRANT_CLOUD_TOKEN
