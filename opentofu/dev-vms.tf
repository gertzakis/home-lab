# Proxmox VMs
# ---
# Create VMs cloned from a cloud-init template

# Create a Proxmox pool for dev
resource "proxmox_pool" "dev" {
  poolid  = "dev"
  comment = "Development VMs"
}


resource "proxmox_vm_qemu" "dev-vms" {
  # Create Dev nodes
  count = 1
  vm_state = "stopped"
  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "17${count.index}"
  name        = "ubuntu-dev-0${count.index + 1}"
  description = "Ubuntu Dev VM ${count.index + 1} \n\n IP `192.168.1.17${count.index}`"
  pool        = "dev"
  tags        = "dev;test" # semicolon separated format

  # VM OS Settings
  clone   = "ubuntu-tmpl-01"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  cpu {
    sockets = 1
    cores   = 2
    type = "host"
  }

  # VM Memory Settings
  memory = 8192

  # VM Disk Settings
  # cloudinit_cdrom_storage = "local-lvm" # needed to load the cloud-init drive
  disks {
    ide {
      ide2 {
        cdrom {
          passthrough = false
        }
      }
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = 30
          storage = "local-lvm"
        }
      }
    }
  }

  # VM Network Settings
  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # Credentials passed through cloud-init
  ciuser     = var.vm_username
  cipassword = var.vm_password

  # IP Address and Gateway (cloud-init)
  ipconfig0 = "ip=192.168.1.17${count.index}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}

resource "proxmox_vm_qemu" "kubernetes-test-vms" {
  count = 1
  # vm_state = "stopped"
  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "17${count.index + 5}"
  name        = "k8s-test-vm-0${count.index + 1}"
  description = "Kubernetes test node ${count.index + 1} \n\n IP `192.168.1.17${count.index + 5}`"
  pool        = "dev"
  tags        = "k8s;test" # semicolon separated format

  # VM OS Settings
  clone   = "ubuntu-k8s-24-04-tmpl-01.home.lab"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  cpu {
    sockets = 1
    cores   = 2
    type = "host"
  }

  # VM Memory Settings
  memory = 8192

  # VM Disk Settings
  # cloudinit_cdrom_storage = "local-lvm" # needed to load the cloud-init drive
  disks {
    ide {
      ide2 {
        cdrom {
          passthrough = false
        }
      }
      ide3 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
    virtio {
      virtio0 {
        disk {
          size    = 60
          storage = "local-lvm"
        }
      }
    }
  }

  # VM Network Settings
  network {
    id = 0
    bridge = "vmbr0"
    model  = "virtio"
  }
  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # Credentials passed through cloud-init
  ciuser     = var.vm_username
  cipassword = var.vm_password

  # IP Address and Gateway (cloud-init)
  ipconfig0 = "ip=192.168.1.17${count.index + 5}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}
