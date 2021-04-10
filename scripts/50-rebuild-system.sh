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

if [ -z ${BUILD_KERNEL:-} ]; then
    echo "BUILD_KERNEL was not set. Skipping kernel build."
else
    if [ "$BUILD_KERNEL" = false ]; then
        echo ">>> Skipping kernel build."
    else
        echo ">>> Building kernel ..."
        cd /usr/src/linux
        sudo make distclean
        sudo genkernel all
        sudo ego boot update
    fi
fi

sudo env-update
source /etc/profile

# sync any guest packages to host (via shared folder)
sudo rsync -urv /var/cache/portage/packages/* /vagrant/packages/
