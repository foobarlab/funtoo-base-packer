#!/bin/bash

# this script will use an existing box version
# or generate a new box version in semantic
# versioning format: major.minor.buildnumber
# as required by Vagrant

if [ -f build_version ]; then
	BUILD_BOX_VERSION=$(<build_version)
else
	# get major version (must exist as file 'version'):
	BUILD_MAJOR_VERSION=$(<version)
	# generate minor version (date in format YYMMDD):
	BUILD_MINOR_VERSION=$(date -u +%y%m%d)
	# take existing env var BUILD_NUMBER, increment the one stored in
	# file 'build_number' or initialize a new one beginning with 100000:
	if [ -z ${BUILD_NUMBER:-} ] ; then
		if [ -f build_number ]; then
			# read from file and increase by one
			BUILD_NUMBER=$(<build_number)
			BUILD_NUMBER=$((BUILD_NUMBER+1))
		else
			BUILD_NUMBER=1
		fi
		# store for later reuse in file 'build_number'
		echo $BUILD_NUMBER > build_number
		export BUILD_NUMBER
	fi
	BUILD_BOX_VERSION=$BUILD_MAJOR_VERSION.$BUILD_MINOR_VERSION.$BUILD_NUMBER
fi

# store in env var
export BUILD_BOX_VERSION

# store in file 'build version'
echo $BUILD_BOX_VERSION > build_version
