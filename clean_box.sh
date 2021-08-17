#!/bin/bash -ue
# vim: ts=4 sw=4 et

. config.sh quiet

require_commands vagrant

highlight "Removing Vagrant box ..."
step "Suspending any running instances named '$BUILD_BOX_NAME' ..."
vagrant suspend "$BUILD_BOX_NAME" 2>/dev/null || true
step "Destroying current box ..."
vagrant destroy -f || true
step "Removing box '$BUILD_BOX_NAME' ..."
vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
