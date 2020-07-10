# Funtoo Base Vagrant box

This is a minimal Funtoo Linux that is packaged into a Vagrant box file. Currently only a VirtualBox version is provided.
It is based on the [Funtoo Stage3 Vagrant box](https://github.com/foobarlab/funtoo-stage3-packer) and can be used for bootstrapping your own box.

### What's included?

 - Minimal Funtoo Linux 1.4 installation ('server' profile)
 - Architecture: x86-64bit, generic_64
 - 40 GB dynamic sized HDD image (ext4)
 - Timezone: ```UTC```
 - NAT Networking using DHCP (virtio)
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default SSH authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Debian Kernel 5.4, stripped down for use with VirtualBox
 - Optional: switch and rebuild a non-default GCC version (experimental, default: disabled)
 - Optional: rebuild world, recompile the whole system (experimental, default: disabled)
 - Optional: unrestricted licenses (creates a non-free version, default: disabled)
 - Optional: include *Ansible* (for automation, default: enabled)
 - List of additional installed software:
    - Kernel tools: *genkernel, eclean-kernel*
    - *rsyslog* for logging
    - *vim* as default editor
    - *gpm, evtest* for console mouse pointer integration
    - Commandline helpers/tools: *lsof, bash-completion, screen, tmux, htop, ncdu, mc*
	- Network utils for www, ftp and email: *links, ncftp, mutt*
	- *Terminus* console font (12 to 32px)
    - Any additional software installed in the [stage3 box](https://github.com/foobarlab/funtoo-stage3-packer)

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-base](https://app.vagrantup.com/foobarlab/boxes/funtoo-base)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build a fresh VirtualBox box

 - Run ```./build.sh```
 
#### Quick test the box file

 - Run ```./test.sh```

#### Upload the box to Vagrant Cloud (experimental)

 - Run ```./upload.sh```

### Regular use cases

#### Initialize a fresh box (initial state, any modifications are lost)

 - Run ```./init.sh```

#### Power on the box (keeping previous state)

 - Run ```./startup.sh```

### Special use cases

#### Show current build config

 - Run ```./config.sh```

#### Cleanup build environment (poweroff all Vagrant and VirtualBox machines)

 - Run ```./clean_env.sh```

#### Generate Vagrant Cloud API Token

 - Run ```./vagrant_cloud_token.sh```

#### Keep only a maximum number of boxes in Vagrant Cloud (experimental)

 - Run ```./clean_cloud.sh```

## Feedback welcome

Please create an issue.
