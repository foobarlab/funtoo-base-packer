#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_GCC_VERSION:-} ]; then
	echo "BUILD_GCC_VERSION was not set. Skipping GCC install ..."
	exit 0
fi

# install GCC, see: https://wiki.gentoo.org/wiki/Upgrading_GCC

echo "Installing GCC ${BUILD_GCC_VERSION} ..."

sudo mkdir -p /etc/portage/package.unmask
cat <<'DATA' | sudo tee -a /etc/portage/package.unmask/gcc
=sys-devel/gcc-BUILD_GCC_VERSION
DATA
sudo sed -i 's/BUILD_GCC_VERSION/'"$BUILD_GCC_VERSION"'/g' /etc/portage/package.unmask/gcc
sudo cat /etc/portage/package.unmask/gcc

sudo emerge -v --oneshot sys-devel/gcc:${BUILD_GCC_VERSION}

sudo gcc-config "x86_64-pc-linux-gnu-${BUILD_GCC_VERSION}"

sudo emerge -v --oneshot sys-devel/libtool
sudo emerge -vt --depclean sys-devel/gcc

sudo gcc-config --list-profiles

sudo env-update
source /etc/profile
