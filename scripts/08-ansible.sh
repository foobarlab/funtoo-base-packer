#!/bin/bash -uex

if [ -z ${BUILD_RUN:-} ]; then
  echo "This script can not be run directly! Aborting."
  exit 1
fi

if [ -z ${BUILD_INCLUDE_ANSIBLE:-} ]; then
	echo "BUILD_INCLUDE_ANSIBLE was not set. Skipping ..."
	exit 0
else
	if [ "$BUILD_INCLUDE_ANSIBLE" = "false" ]; then
		echo "BUILD_INCLUDE_ANSIBLE set to FALSE. Skipping ..."
		exit 0
	fi	
fi

# install and configure Ansible for automation
sudo emerge -vt app-admin/ansible
sudo mkdir -p /etc/ansible
cat <<'DATA' | sudo tee -a /etc/ansible/ansible.cfg
# disable SSH host key checking, see: https://www.vagrantup.com/docs/provisioning/ansible_local.html
[defaults]
host_key_checking = no
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
DATA
