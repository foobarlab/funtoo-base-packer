#!/bin/bash -e

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${SCRIPTS:-} ]; then
  SCRIPTS=.
fi

chmod +x $SCRIPTS/scripts/*.sh

for script in \
  01-prepare \
  02-kernel \
  03-system-update \
  04-gcc-upgrade \
  05-rebuild-system \
  06-software \
  07-spectre \
  08-ansible \
  09-postprocess \
  10-cleanup
do
  echo "==============================================================================="
  echo " >>> Running $script.sh"
  echo "==============================================================================="
  "$SCRIPTS/scripts/$script.sh"
  printf "\n\n"
done

echo "All done."
