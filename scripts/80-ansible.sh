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

# FIXME Ansible 2.10.0 fails, 2.9 is no more available (FL-7505)
# stay in 2.9 => mask 2.10
# get 2.10 => update ebuilds, emerge 'ansible-base' + collection download (alternative: packaged both into 'ansible'?)

sudo emerge -nuvtND --with-bdeps=y app-admin/ansible
sudo mkdir -p /etc/ansible
cat <<'DATA' | sudo tee -a /etc/ansible/ansible.cfg
[defaults]
host_key_checking = no				# disable SSH host key checking, see: https://www.vagrantup.com/docs/provisioning/ansible_local.html
interpreter_python = auto_silent	# Python discovery, see: https://docs.ansible.com/ansible/latest/reference_appendices/interpreter_discovery.html
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes
DATA
