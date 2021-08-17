#!/bin/bash -ue
# vim: ts=4 sw=4 et

. config.sh quiet

require_commands vagrant

title "TEST BOX"

if [ -f "$BUILD_OUTPUT_FILE" ];
then
    highlight "Testing '$BUILD_BOX_NAME' box ..."
    step "Suspending any running instances ..."
    vagrant suspend
    step "Destroying current box ..."
    vagrant destroy -f || true
    step "Removing '$BUILD_BOX_NAME' ..."
    vagrant box remove -f "$BUILD_BOX_NAME" 2>/dev/null || true
    step "Adding '$BUILD_BOX_NAME' ..."
    vagrant box add --name "$BUILD_BOX_NAME" "$BUILD_OUTPUT_FILE"
    step "Powerup '$BUILD_BOX_NAME' ..."
    vagrant up --no-provision || { echo "Failed to startup '$BUILD_BOX_NAME'. Test failed!"; exit 1; }
    step "Suspending '$BUILD_BOX_NAME' ..."
    vagrant suspend
else
    error "There is no box file '$BUILD_OUTPUT_FILE' in the current directory."
    info "Please place the box file here or use './build.sh' to create a box file."
    if [ $# -eq 0 ]; then
        exit 1  # exit with error when running without param
    else
        exit 0  # silently exit when running with param
    fi
fi

result "Test passed."
