# Funtoo Base Vagrant box

This is a minimal Funtoo Linux that is packaged into a Vagrant box file. Currently only a VirtualBox version is provided.
It is based on the [Funtoo Stage3 Vagrant box](https://github.com/foobarlab/funtoo-stage3-packer) and can be used for bootstrapping your own box.

### What's included?

 - Minimal Funtoo Linux 1.4 installation ('server' profile)
 - Optional: experimental Funtoo next installation (work-in-progress)
 - Architecture: x86-64bit, intel64-nehalem (compatible with most CPUs since 2008) respectively generic_64 (Funtoo next)
 - Initial 20 GB dynamic sized HDD image (ext4), can be expanded
 - Timezone: ```UTC```
 - NAT Networking using DHCP (virtio)
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password), additionally using the default SSH authorized keys provided by Vagrant (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Optional: Debian Kernel 5.10 (debian-sources) stripped down for use with VirtualBox (default: enabled)
 - Optional: switch and rebuild a non-default GCC version (experimental, default: disabled)
 - Optional: rebuild world, recompile the whole system (experimental, default: disabled)
 - Optional: include *Ansible* (for automation, default: enabled)
 - Optional: include 3D-enabled *X.Org* server and the lightweight *Fluxbox* window manager (experimental, default: enabled)
 - List of additional installed software:
    - Kernel build tool *genkernel*
    - *rsyslog* for logging
    - *vixie-cron* for cronjob services
    - *vim* as default editor
    - *haveged* providing entropy
    - Commandline helpers/tools: *progress, tree, lsof, hdparm, bash-completion, screen, tmux, htop, ncdu, mc*
    - Portage utils: *eix, genlop*
    - Additional shells: *zsh, dash*
    - Network utils for www, ftp and email: *links, ncftp, mutt*
    - *Terminus* console font (12 to 32px)
    - *sshfs* for alternative shared folder mechanism (e.g. use with [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs))
    - Any additional software installed in the [stage3 box](https://github.com/foobarlab/funtoo-stage3-packer)
 - Scripts for system administration in */usr/local/sbin*:
    - *foo-sync*: wrapper to sync meta-repo and any overlays
    - *foo-update*: wrapper to install @world updates
    - *foo-setup-non-free*: apply licensing and distribution changes to make.conf (make it 'non-free')
    - *foo-cleanup*: delete temporay files for housekeeping
    - *foo-prepare-compact*: zero-fill free disk space to prepare for hdd image compaction

### Enable Desktop

Enter ```sudo rc-update add xdm default``` and reboot.

### Download pre-build images

Get the latest build from Vagrant Cloud: [foobarlab/funtoo-base](https://app.vagrantup.com/foobarlab/boxes/funtoo-base)

### Build your own using Packer

#### Preparation

 - Install [Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/)

#### Build a fresh VirtualBox box

 - Run ```./build.sh```
 
#### Quick test the box file

 - Run ```./test.sh```

#### Upload the box to Vagrant Cloud (account required)

 - Run ```./upload.sh```

### Regular use cases

#### Initialize a fresh box (initial state, any modifications are lost)

 - Run ```./init.sh```

#### Power on the box (keeping previous state)

 - Run ```./startup.sh```

### Special use cases

#### Show current build config

 - Run ```./config.sh```

#### Cleanup build environment (poweroff and remove any related Vagrant and VirtualBox machines)

 - Run ```./clean_env.sh```

#### Cleanup temporary build Vagrant box

 - Run ```./clean_box.sh```

#### Cleanup build environment

 - Run ```./clean.sh```

#### Generate Vagrant Cloud API Token

 - Run ```./vagrant_cloud_token.sh```

#### Keep only a maximum number of boxes in Vagrant Cloud (experimental)

 - Run ```./clean_cloud.sh```

## Feedback and bug reports welcome

Please create an issue or submit a pull request.
