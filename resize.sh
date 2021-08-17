#!/bin/bash -ue
# vim: ts=2 sw=2 et

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

echo "Resizing disk ..."
sudo growpart /dev/sda 4 || true
sudo resize2fs /dev/sda4 || true

echo "Resize result:"
sudo fdisk -l || true

echo "Rebooting ..."
sudo reboot
