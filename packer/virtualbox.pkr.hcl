packer {
  required_version = ">= 1.7.1"
}

variable "box_description" {
  type    = string
  default = "${env("BUILD_BOX_DESCRIPTION")}"
}

variable "box_version" {
  type    = string
  default = "${env("BUILD_BOX_VERSION")}"
}

variable "cpus" {
  type    = string
  default = "${env("BUILD_CPUS")}"
}

variable "custom_overlay" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY")}"
}

variable "custom_overlay_branch" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_BRANCH")}"
}

variable "custom_overlay_name" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_NAME")}"
}

variable "custom_overlay_url" {
  type    = string
  default = "${env("BUILD_CUSTOM_OVERLAY_URL")}"
}

variable "flavor" {
  type    = string
  default = "${env("BUILD_FLAVOR")}"
}

variable "gcc_version" {
  type    = string
  default = "${env("BUILD_GCC_VERSION")}"
}

variable "git_commit_id" {
  type    = string
  default = "${env("BUILD_GIT_COMMIT_ID")}"
}

variable "guest_os_type" {
  type    = string
  default = "${env("BUILD_GUEST_TYPE")}"
}

variable "headless" {
  type    = string
  default = "${env("BUILD_HEADLESS")}"
}

variable "include_ansible" {
  type    = string
  default = "${env("BUILD_INCLUDE_ANSIBLE")}"
}

variable "kernel" {
  type    = string
  default = "${env("BUILD_KERNEL")}"
}

variable "makeopts" {
  type    = string
  default = "${env("BUILD_MAKEOPTS")}"
}

variable "memory" {
  type    = string
  default = "${env("BUILD_MEMORY")}"
}

variable "output_file" {
  type    = string
  default = "${env("BUILD_OUTPUT_FILE_TEMP")}"
}

variable "rebuild_system" {
  type    = string
  default = "${env("BUILD_REBUILD_SYSTEM")}"
}

variable "report_spectre" {
  type    = string
  default = "${env("BUILD_REPORT_SPECTRE")}"
}

variable "source_path" {
  type    = string
  default = "${env("BUILD_PARENT_OVF")}"
}

variable "timestamp" {
  type    = string
  default = "${env("BUILD_TIMESTAMP")}"
}

variable "username" {
  type    = string
  default = "vagrant"
}

variable "password" {
  type    = string
  default = "vagrant"
}

variable "vdi_path" {
  type    = string
  default = "${env("BUILD_PARENT_BOX_CLOUD_VDI")}"
}

variable "vm_name" {
  type    = string
  default = "${env("BUILD_BOX_NAME")}"
}

variable "vm_username" {
  type    = string
  default = "${env("BUILD_BOX_USERNAME")}"
}

variable "window_system" {
  type    = string
  default = "${env("BUILD_WINDOW_SYSTEM")}"
}

source "virtualbox-ovf" "gold" {
  boot_wait            = "30s"
  guest_additions_mode = "disable"
  headless             = "${var.headless}"
  shutdown_command     = "echo 'packer' | sudo -S shutdown -P now"
  source_path          = "${var.source_path}"
  ssh_password         = "${var.password}"
  ssh_private_key_file = "keys/vagrant"
  ssh_pty              = "true"
  ssh_username         = "${var.username}"
  ssh_wait_timeout     = "30s"
  vboxmanage           = [
    ["modifyvm", "{{ .Name }}", "--memory", "${var.memory}"],
    ["modifyvm", "{{ .Name }}", "--cpus", "${var.cpus}"],
    ["modifyvm", "{{ .Name }}", "--nictype1", "virtio"],
    ["modifyvm", "{{ .Name }}", "--audio", "pulse"],
    ["modifyvm", "{{ .Name }}", "--audiocontroller", "hda"],
    ["modifyvm", "{{ .Name }}", "--audioin", "on"],
    ["modifyvm", "{{ .Name }}", "--audioout", "on"],
    ["modifyvm", "{{ .Name }}", "--usb", "on"],
    ["modifyvm", "{{ .Name }}", "--usbehci", "off"],
    ["modifyvm", "{{ .Name }}", "--usbxhci", "off"],
    ["modifyvm", "{{ .Name }}", "--chipset", "ich9"],
    ["modifyvm", "{{ .Name }}", "--rtcuseutc", "on"],
    ["modifyvm", "{{ .Name }}", "--vram", "64"],
    ["modifyvm", "{{ .Name }}", "--vrde", "off"],
    ["modifyvm", "{{ .Name }}", "--hpet", "on"],
    ["modifyvm", "{{ .Name }}", "--hwvirtex", "on"],
    ["modifyvm", "{{ .Name }}", "--vtxvpid", "on"],
    ["modifyvm", "{{ .Name }}", "--nested-hw-virt", "on"],
    ["modifyvm", "{{ .Name }}", "--largepages", "on"],
    ["modifyvm", "{{ .Name }}", "--graphicscontroller", "vmsvga"],
    ["modifyvm", "{{ .Name }}", "--accelerate3d", "on"],
    ["modifyvm", "{{ .Name }}", "--spec-ctrl", "off"],
    ["modifyvm", "{{ .Name }}", "--clipboard-mode", "bidirectional"],
    ["sharedfolder", "add", "{{ .Name }}", "--name=/vagrant", "--hostpath=.", "--automount"],
    ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "0", "--device", "0", "--nonrotational", "on", "--type", "hdd", "--medium", "${var.vdi_path}"]
  ]
  vm_name              = "${var.vm_name}"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "${var.box_description}",
    "--version", "${var.box_version}"
  ]
}

build {
  sources = ["source.virtualbox-ovf.gold"]
  provisioner "shell" {
    environment_vars  = ["BUILD_RUN=true"]
    expect_disconnect = true
    pause_after       = "30s"
    pause_before      = "1s"
    script            = "packer/resize.sh"
    timeout           = "10m0s"
    valid_exit_codes  = [0]
  }
  provisioner "file" {
    destination = "/tmp"
    source      = "packer/scripts"
  }
  provisioner "file" {
    destination = "/tmp/sbin"
    source      = "packer/scripts/sbin"
  }
  provisioner "shell" {
    environment_vars  = [
      "scripts=/tmp",
      "BUILD_RUN=true",
      "BUILD_BOX_NAME=${var.vm_name}",
      "BUILD_BOX_USERNAME=${var.vm_username}",
      "BUILD_BOX_DESCRIPTION=${var.box_description}",
      "BUILD_GCC_VERSION=${var.gcc_version}",
      "BUILD_BOX_VERSION=${var.box_version}",
      "BUILD_GIT_COMMIT_ID=${var.git_commit_id}",
      "BUILD_MAKEOPTS=${var.makeopts}",
      "BUILD_TIMESTAMP=${var.timestamp}",
      "BUILD_REBUILD_SYSTEM=${var.rebuild_system}",
      "BUILD_FLAVOR=${var.flavor}",
      "BUILD_REPORT_SPECTRE=${var.report_spectre}",
      "BUILD_INCLUDE_ANSIBLE=${var.include_ansible}",
      "BUILD_KERNEL=${var.kernel}",
      "BUILD_WINDOW_SYSTEM=${var.window_system}",
      "BUILD_CUSTOM_OVERLAY=${var.custom_overlay}",
      "BUILD_CUSTOM_OVERLAY_NAME=${var.custom_overlay_name}",
      "BUILD_CUSTOM_OVERLAY_URL=${var.custom_overlay_url}",
      "BUILD_CUSTOM_OVERLAY_BRANCH=${var.custom_overlay_branch}"
    ]
    expect_disconnect = false
    script            = "packer/provision.sh"
  }
  post-processor "checksum" {
    checksum_types = ["sha1"]
    output         = "packer.{{.ChecksumType}}.checksum"
  }
  post-processor "vagrant" {
    keep_input_artifact = false
    output              = "${var.output_file}"
  }
}
