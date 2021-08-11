#!/bin/bash -ue
# vim: ts=4 sw=4 et

. config.sh quiet

require_commands vagrant

title "INITIALIZE BOX"

if [ -f "$BUILD_OUTPUT_FILE" ]; then
  highlight "Initializing a fresh '$BUILD_BOX_NAME' box ..."
    step "Suspending any running instances ..."
    vagrant suspend
    step"Destroying current box ..."
    vagrant destroy -f || true
    step "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    step "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE"
else
    error "There is no box file '$BUILD_OUTPUT_FILE' in the current directory."
    result "Please run './build.sh' to build a box."
    exit 1
fi

final "Box installed and ready to use. You may now enter './startup.sh' to boot the box."
