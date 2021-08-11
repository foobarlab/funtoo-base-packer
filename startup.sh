#!/bin/bash -ue
# vim: ts=4 sw=4 et

. config.sh

require_commands vagrant

title "Starting '$BUILD_BOX_NAME'"

step "Powerup '$BUILD_BOX_NAME' ..."
vagrant up --no-provision || { echo "Unable to startup '$BUILD_BOX_NAME'."; exit 1; }
step "Establishing SSH connection to '$BUILD_BOX_NAME' ..."
vagrant ssh
