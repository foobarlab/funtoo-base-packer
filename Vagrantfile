# -*- mode: ruby -*-
# vi: set ft=ruby :

system("./config.sh >/dev/null")

$script_export_packages = <<SCRIPT
# clean host packages dir
rm -rf /vagrant/packages/*
# move guest packages to host
mv -f /var/cache/portage/packages/* /vagrant/packages/
# let it settle
sync && sleep 15
SCRIPT

$script_clean_kernel = <<SCRIPT
# clean stale kernel files
mount /boot || true
eclean-kernel -l
eclean-kernel -n 1
ego boot update
# clean kernel sources
cd /usr/src/linux
make distclean
# copy latest kernel config
cp -f /usr/src/kernel.config /usr/src/linux/.config
# prepare for module compiles
make olddefconfig
make modules_prepare
SCRIPT

$script_cleanup = <<SCRIPT
# debug: list running services
rc-status
# stop services
/etc/init.d/xdm stop || true
/etc/init.d/xdm-setup stop || true
/etc/init.d/elogind stop || true
/etc/init.d/gpm stop || true
/etc/init.d/rsyslog stop
/etc/init.d/dbus -D stop
/etc/init.d/haveged stop
/etc/init.d/udev stop
/etc/init.d/vixie-cron stop
/etc/init.d/dhcpcd stop
/etc/init.d/local stop
/etc/init.d/acpid stop
# let it settle
sync && sleep 15
# debug: list running services
rc-status
# run zerofree at last to squeeze the last bit
# /boot
mount -o remount,ro /dev/sda1
zerofree -v /dev/sda1
# /
mount -o remount,ro /dev/sda4
zerofree -v /dev/sda4
# swap
swapoff -v /dev/sda3
bash -c 'dd if=/dev/zero of=/dev/sda3 2>/dev/null' || true
mkswap /dev/sda3
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.box = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.hostname = "#{ENV['BUILD_BOX_NAME']}"
  config.vm.provider "virtualbox" do |vb|
    vb.gui = (ENV['BUILD_HEADLESS'] == "false")
    vb.memory = "#{ENV['BUILD_BOX_MEMORY']}"
    vb.cpus = "#{ENV['BUILD_BOX_CPUS']}"
    # customize VirtualBox settings, see also 'virtualbox.json'
    vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
    vb.customize ["modifyvm", :id, "--audio", "none"]
    vb.customize ["modifyvm", :id, "--usb", "off"]
    vb.customize ["modifyvm", :id, "--rtcuseutc", "on"]
    vb.customize ["modifyvm", :id, "--chipset", "ich9"]
    vb.customize ["modifyvm", :id, "--vram", "64"]
    vb.customize ["modifyvm", :id, "--vrde", "off"]
    vb.customize ["modifyvm", :id, "--hpet", "on"]
    vb.customize ["modifyvm", :id, "--hwvirtex", "on"]
    vb.customize ["modifyvm", :id, "--vtxvpid", "on"]
    vb.customize ["modifyvm", :id, "--largepages", "on"]
    vb.customize ["modifyvm", :id, "--graphicscontroller", "vmsvga"]
    vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
  end
  config.ssh.pty = true
  config.ssh.insert_key = false
  config.vm.synced_folder '.', '/vagrant', disabled: false
  config.vm.provision "export_packages", type: "shell", inline: $script_export_packages, privileged: true
  config.vm.provision "clean_kernel", type: "shell", inline: $script_clean_kernel, privileged: true
  config.vm.provision "cleanup", type: "shell", inline: $script_cleanup, privileged: true
end
