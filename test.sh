#!/bin/bash -ue

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh

echo "--- Testing '$BUILD_BOX_NAME' box ..."

if [ -f "$BUILD_OUTPUT_FILE" ];
then
	echo "--- Suspending any running instances ..."
	vagrant suspend
	echo "--- Destroying current box ..."
	vagrant destroy -f || true
	echo "--- Removing '$BUILD_BOX_NAME' ..."
	vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
	echo "--- Adding '$BUILD_BOX_NAME' ..."
	vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE"
	echo "--- Powerup '$BUILD_BOX_NAME' ..."
	vagrant up --no-provision || { echo "Failed to startup '$BUILD_BOX_NAME'. Test failed!"; exit 1; } 
	echo "--- Suspending '$BUILD_BOX_NAME' ..."
	vagrant suspend
else
	echo "There is no box file '$BUILD_OUTPUT_FILE' in the current directory. Please place the box file here or use './build.sh' to create a box file."
	if [ $# -eq 0 ]; then
		exit 1	# exit with error when running without param
	else
		exit 0	# silently exit when running with param
	fi 
fi

echo "Test passed."
