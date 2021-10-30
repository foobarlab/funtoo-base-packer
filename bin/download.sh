#!/bin/bash -ue
# vim: ts=4 sw=4 et

source "${BUILD_LIB_UTILS:-./bin/lib/utils.sh}" "$*"

title "DOWNLOAD BOX"

todo "get latest version from vagrant cloud and write build_version, extract build_number"

step "power on vagrant"
vagrant up 