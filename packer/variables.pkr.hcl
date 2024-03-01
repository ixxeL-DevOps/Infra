# Copyright 2023-2024 Broadcom. All rights reserved.
# SPDX-License-Identifier: BSD-2

/*
    DESCRIPTION:
    Ubuntu Server 22.04 LTS build variables.
*/

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

