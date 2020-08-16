#!/bin/bash -ue

command -v vagrant >/dev/null 2>&1 || { echo "Command 'vagrant' required but it's not installed.  Aborting." >&2; exit 1; }

. config.sh

echo "Suspending any running instances ..."
vagrant suspend && true
echo "Destroying current box ..."
vagrant destroy -f || true
echo "Removing box '$BUILD_BOX_NAME' ..."
vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
echo "Cleaning .vagrant dir ..."
rm -vrf .vagrant/ || true
echo "Cleaning packer_cache ..."
rm -vrf packer_cache/ || true
echo "Cleaning packer output-virtualbox-ovf dir ..."
rm -vrf output-virtualbox-ovf || true
echo "Drop build number ..."
rm -vf build_number || true
echo "Drop build version ..."
rm -vf build_version || true
echo "Drop major version ..."
rm -vf version || true
echo "Deleting any box file ..."
rm -vf *.box || true
echo "Cleanup old logs ..."
rm -vf *.log || true
echo "Cleanup broken wget downloads ..."
rm -vf download || true
echo "All done. You may now run './build.sh' to build a fresh box."
