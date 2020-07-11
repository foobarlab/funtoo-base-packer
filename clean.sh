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
rm -rf .vagrant/ || true
echo "Cleaning packer_cache ..."
rm -rf packer_cache/ || true
echo "Cleaning packer output-virtualbox-ovf dir ..."
rm -rf output-virtualbox-ovf || true
echo "Drop build version ..."
rm -f build_version || true
echo "Deleting any box file ..."
rm -f *.box || true
echo "Cleanup old logs ..."
rm -f *.log || true
echo "Cleanup broken wget downloads ..."
rm -f download || true
echo "All done. You may now run './build.sh' to build a fresh box."
