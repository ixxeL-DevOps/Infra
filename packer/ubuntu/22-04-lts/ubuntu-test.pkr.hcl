# Ubuntu Server jammy
# ---
# Packer Template to create an Ubuntu Server (jammy) on Proxmox

// Variables

// Proxmox settings
variable "proxmox_api_url" {
    type = string
}

variable "proxmox_api_token_id" {
    type = string
}

variable "proxmox_api_token_secret" {
    type = string
    sensitive = true
}

variable "proxmox_insecure_connection" {
  type        = bool
  default     = true
}

variable "proxmox_node" {
    type = string
    default = "proxmox-big"
}

// Virtual Machine OS settings
variable "vm_guest_os_language" {
  type        = string
  default     = "en_US"
}

variable "vm_guest_os_keyboard" {
  type        = string
  default     = "us"
}

variable "vm_guest_os_timezone" {
  type        = string
  default     = "UTC"
}

variable "vm_guest_os_family" {
  type        = string
  default = "linux"
}

variable "vm_guest_os_name" {
  type        = string
  default = "ubuntu"
}

variable "vm_guest_os_version" {
  type        = string
  default = "22.04-lts"
}

variable "vm_umount_iso" {
  type        = bool
  default     = true
}

variable "vm_cpu_cores" {
  type        = string
  default     = "1"
}

variable "vm_mem_size" {
  type        = string
  default     = "2048"
}

variable "vm_scsi_controller" {
  type        = string
  default     = "virtio-scsi-pci"
}

// VM disks
variable "vm_disk_size" {
  type        = string
  default     = "20G"
}

variable "vm_disk_format" {
  type        = string
  default     = "raw"
}

variable "vm_disk_type" {
  type        = string
  default     = "virtio"
}

variable "vm_disk_storage_pool_type" {
  type        = string
  default     = "lvm"
}

variable "vm_disk_storage_pool" {
  type        = string
  default     = "local-lvm"
}

// VM network adapters

variable "vm_net_model" {
  type        = string
  default     = "virtio"
}

variable "vm_net_bridge" {
  type        = string
  default     = "vmbr0"
}

variable "vm_net_firewall" {
  type        = string
  default     = "false"
}

locals {
  build_by          = "Built by: HashiCorp Packer ${packer.version}"
  build_date        = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
  vm_name = "${var.vm_guest_os_family}-${var.vm_guest_os_name}-${var.vm_guest_os_version}"
  tpl_description = "${var.vm_guest_os_name} server ${var.vm_guest_os_version}"
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-server-jammy" {
 
    # Proxmox Connection Settings
    proxmox_url = var.proxmox_api_url
    username = var.proxmox_api_token_id
    token = var.proxmox_api_token_secret
    # (Optional) Skip TLS Verification
    insecure_skip_tls_verify = var.proxmox_insecure_connection
    
    # VM General Settings
    node = var.proxmox_node
    vm_id = "110"
    vm_name = local.vm_name
    template_description = local.tpl_description

    # VM OS Settings
    # (Option 1) Local ISO File
    iso_file = "QNAP:iso/ubuntu-22.04.1-live-server-amd64.iso"
    # - or -
    # (Option 2) Download ISO
    # iso_url = "https://releases.ubuntu.com/22.04/ubuntu-22.04-live-server-amd64.iso"
    # iso_checksum = "84aeaf7823c8c61baa0ae862d0a06b03409394800000b3235854a6b38eb4856f"
    iso_storage_pool = "QNAP"
    unmount_iso = var.vm_umount_iso

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = var.vm_scsi_controller

    disks {
        disk_size = var.vm_disk_size
        format = var.vm_disk_format
        storage_pool = var.vm_disk_storage_pool
        // storage_pool_type = var.vm_disk_storage_pool_type
        type = var.vm_disk_type
    }
    network_adapters {
        model = var.vm_net_model
        bridge = var.vm_net_bridge
        firewall = var.vm_net_firewall
    } 

    # VM CPU Settings
    cores = var.vm_cpu_cores
    
    # VM Memory Settings
    memory = var.vm_mem_size

    # VM Network Settings


    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local-lvm"

    # PACKER Boot Commands
    boot_command = [
        // This waits for 3 seconds, sends the "c" key, and then waits for another 3 seconds. In the GRUB boot loader, this is used to enter command line mode.
        "<wait3s>c<wait3s>",
        // This types a command to load the Linux kernel from the specified path with the 'autoinstall' option and the value of the 'data_source_command' local variable. 
        // The 'autoinstall' option is used to automate the installation process. 
        // The 'data_source_command' local variable is used to specify the kickstart data source configured in the common variables. 
        "linux /casper/vmlinuz --- autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        // This sends the "enter" key and then waits. This is typically used to execute the command and give the system time to process it.
        "<enter><wait>",
        // This types a command to load the initial RAM disk from the specified path.
        "initrd /casper/initrd",
        // This sends the "enter" key and then waits. This is typically used to execute the command and give the system time to process it.
        "<enter><wait>",
        // This types the "boot" command. This starts the boot process using the loaded kernel and initial RAM disk.
        "boot",
        // This sends the "enter" key. This is typically used to execute the command.
        "<enter>"
    ]

    // boot_command = [
    //     "<esc><wait>",
    //     "e<wait>",
    //     "<down><down><down><end>",
    //     "<bs><bs><bs><bs><wait>",
    //     "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    //     "<f10><wait>"
    // ]
    boot = "c"
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "packer/ubuntu/22-04-lts/http" 
    # (Optional) Bind IP Address and Port
    # http_bind_address = "0.0.0.0"
    # http_port_min = 8802
    # http_port_max = 8802

    ssh_username = "fred"

    # (Option 1) Add your Password here
    # ssh_password = "your-password"
    # - or -
    # (Option 2) Add your Private SSH KEY file here
    ssh_private_key_file = "~/.ssh/vm"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-server-jammy"
    sources = ["source.proxmox-iso.ubuntu-server-jammy"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo rm -f /etc/netplan/00-installer-config.yaml",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "packer/ubuntu/22-04-lts/files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Provisioning the VM Template with Docker Installation #4
    provisioner "shell" {
        inline = [
            "sudo apt-get install -y ca-certificates curl gnupg lsb-release",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
            "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "sudo apt-get -y update",
            "sudo apt-get install -y docker-ce docker-ce-cli containerd.io"
        ]
    }
}