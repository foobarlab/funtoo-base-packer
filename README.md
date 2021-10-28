# Funtoo Base box packer

This is a minimal Funtoo Linux that is packaged into a Vagrant box file.
Currently only a VirtualBox version is provided.
It is based on the [Funtoo Stage3 Vagrant box](https://github.com/foobarlab/funtoo-stage3-packer)
and can be used for bootstrapping your own box.

## Operating system

 - Minimal Funtoo Linux 1.4 installation ('server' profile)
 - Optional: experimental Funtoo next installation (work-in-progress)
 - Architecture: x86-64bit, intel64-nehalem (compatible with most CPUs since 2008)
   respectively generic_64 (Funtoo next)
 - Initial 20 GB dynamic sized HDD image (ext4), can be expanded
 - Timezone: UTC
 - NAT networking (virtio) by default
 - Vagrant user *vagrant* with password *vagrant* (can get superuser via sudo without password),
   additionally using the default SSH authorized keys provided by Vagrant
   (see https://github.com/hashicorp/vagrant/tree/master/keys) 
 - Optional: Debian Kernel 5.10 (debian-sources) stripped down for use with VirtualBox (default: enabled)
 - Optional: switch and rebuild a non-default GCC version (experimental, default: disabled)
 - Optional: rebuild world, recompile the whole system (experimental, default: disabled)
 - Optional: include *Ansible* (for automation, default: enabled)
 - Optional: include 3D-enabled *X.Org* server and the lightweight
  *Fluxbox* window manager (experimental, default: enabled)

## Basic applications and utils

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
 - *sshfs* for alternative shared folder mechanism
   (e.g. use with [vagrant-sshfs](https://github.com/dustymabe/vagrant-sshfs))

## Additional tools

Scripts for system administration in */usr/local/sbin*:

 - *foo-sync*: wrapper to sync meta-repo and any overlays
 - *foo-update*: wrapper to install @world updates
 - *foo-setup-non-free*: apply licensing and distribution changes to make.conf (make it 'non-free')
 - *foo-cleanup*: delete temporay files for housekeeping
 - *foo-prepare-compact*: zero-fill free disk space to prepare for hdd image compaction

### Enable Desktop

Enter ```sudo rc-update add xdm default``` and reboot.

### Download pre-build images

Get the latest build from Vagrant Cloud:
[foobarlab/funtoo-base](https://app.vagrantup.com/foobarlab/boxes/funtoo-base)

## Build your own using Packer

Install [VirtualBox](https://www.virtualbox.org) (extensions not needed),
[Vagrant](https://www.vagrantup.com/) and [Packer](https://www.packer.io/).

The provided scripts make use of various commandline utils:

 - bash
 - wget
 - curl
 - jq
 - nproc
 - b2sum
 - git
 - make
 - sed
 - awk
 - grep

Type ```make``` for help, build your own box with ```make all```.

## Feedback and bug reports welcome

Please create an issue or submit a pull request.
