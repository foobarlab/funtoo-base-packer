#!/bin/bash -uex
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_REPORT_SPECTRE:-} ]; then
  echo "BUILD_REPORT_SPECTRE was not set. Skipping ..."
  exit 0
else
  if [ "$BUILD_REPORT_SPECTRE" = "false" ]; then
    echo "BUILD_REPORT_SPECTRE set to FALSE. Skipping ..."
    exit 0
  else
    echo "BUILD_REPORT_SPECTRE set to TRUE. Checking GCC version ..."
    gcc_version=`gcc -dumpversion`
    major=`echo $gcc_version | cut -d. -f1`
    minor=`echo $gcc_version | cut -d. -f2`
    revision=`echo $gcc_version | cut -d. -f3`
    echo "You have GCC $major.$minor.$revision installed."
  fi
fi

# ---- install

sudo emerge -nuvtND --with-bdeps=y app-admin/spectre-meltdown-checker

# ---- report current Spectre/Meltdown status

sudo mount /boot || true
sudo spectre-meltdown-checker -v --explain 2>/dev/null || true

# ---- sync any guest packages to host (via shared folder)

sf_vagrant="`sudo df | grep vagrant | tail -1 | awk '{ print $6 }'`"
sudo rsync -urv /var/cache/portage/packages/* $sf_vagrant/packages/
