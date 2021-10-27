#!/bin/bash -ue
# vim: ts=4 sw=4 et

# FIXME not working? this needs review

. config.sh quiet

require_commands vagrant

highlight "Removing Vagrant box ..."
step "Suspending any running instances named '$BUILD_BOX_NAME' ..."
vagrant suspend "$BUILD_BOX_NAME" >/dev/null 2>&1 || true   # FIXME use id instead of box name?
step "Destroying current box ..."
vagrant destroy -f || true
step "Removing box '$BUILD_BOX_NAME' ..."
vagrant box remove -f "$BUILD_BOX_NAME" >/dev/null 2>&1 || true # FIXME use id instead of box name?
