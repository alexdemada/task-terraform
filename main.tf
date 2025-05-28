terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.39.0"
    }
  }
  required_version = ">= 1.4.0"
}

provider "proxmox" {
  endpoint  = var.pm_api_url
  username  = var.pm_user
  password  = var.pm_password
  insecure  = true
}

# Liste des noms de VM à créer
locals {
  vm_names = ["masteralex", "hubalex", "monialex"]
  ip_addresses = {
    "masteralex" = "192.168.27.26/24"
    "hubalex"      = "192.168.27.28/24"
    "monialex"    = "192.168.27.30/24"
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = toset(local.vm_names)

  name      = each.value
  node_name = "pve"

  clone {
    vm_id        = 9000  # ID du template Cloud-Init existant
    full         = true
    datastore_id = "local-lvm"
  }

  memory {
    dedicated = var.vm_memory
  }

  cpu {
    cores   = var.vm_cores
    sockets = 1
    type    = "host"
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 60
    file_format  = "raw"
  }

  network_device {
    model  = "virtio"
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-lvm"
    user_account {
      username = "root"
      password = "rootroot"
    }

    ip_config {
      ipv4 {
        address = lookup(local.ip_addresses, each.value)
        gateway = "192.168.27.254"
      }
    }

    #user_data = file("${path.module}/cloud-init.yaml")  # Assurez-vous que le fichier cloud-init.yaml est présent dans le même répertoire
  }
}
