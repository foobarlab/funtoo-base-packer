#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_REBUILD_SYSTEM:-} ]; then
	echo "BUILD_REBUILD_SYSTEM was not set. Skipping ..."
	exit 0
else
	if [ "$BUILD_REBUILD_SYSTEM" = false ]; then
		echo "BUILD_REBUILD_SYSTEM set to FALSE. Skipping ..."
		exit 0
	fi	
fi

sudo emerge -vt --emptytree --usepkg=n @system
sudo etc-update --verbose --preen

sudo emerge -vt --emptytree --usepkg=n @world
sudo etc-update --verbose --preen

sudo emerge -vt @preserved-rebuild

sudo perl-cleaner --reallyall
