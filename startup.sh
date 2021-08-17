#!/bin/bash -ue
# vim: ts=4 sw=4 et

. config.sh quiet

require_commands vagrant

title "STARTUP BOX"
step "Powering up '$BUILD_BOX_NAME' ..."
vagrant up --no-provision || { error "Unable to start '$BUILD_BOX_NAME'."; exit 1; }
step "Establishing SSH connection to '$BUILD_BOX_NAME' ..."
vagrant ssh
