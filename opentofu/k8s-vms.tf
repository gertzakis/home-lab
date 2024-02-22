# Proxmox VMs
# ---
# Create VMs cloned from a cloud-init template

resource "proxmox_vm_qemu" "kubernetes-masters" {
  # Create Kubernetes Master nodes
  count = 1

  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "16${count.index}"
  name        = "k8s-master-0${count.index + 1}"
  desc        = "Kubernetes master node ${count.index + 1} \n\n IP `192.168.1.16${count.index}`"
  tags        = "k8s;master" # comma seperated format

  # VM OS Settings
  clone   = "ubuntu-k8s-tmpl-01"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  sockets = 1
  cores   = 2
  cpu     = "host"

  # VM Memory Settings
  memory = 8192

  # VM Disk Settings
  cloudinit_cdrom_storage = "local-lvm" # needed to load the cloud-init drive
  disks {
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
    bridge = "vmbr0"
    model  = "virtio"
  }
  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # Credentials passed through cloud-init
  ciuser     = var.vm_username
  cipassword = var.vm_password

  # IP Address and Gateway (cloud-init)
  ipconfig0 = "ip=192.168.1.16${count.index}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}

resource "proxmox_vm_qemu" "kubernetes-workers" {
  # Create Kubernetes Worker nodes
  count = 2

  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "16${count.index + 3}"
  name        = "k8s-worker-0${count.index + 1}"
  desc        = "Kubernetes worker node ${count.index + 1} \n\n IP `192.168.1.16${count.index + 3}`"
  tags        = "k8s;worker" # comma seperated format

  # VM OS Settings
  clone   = "ubuntu-k8s-tmpl-01"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  sockets = 1
  cores   = 2
  cpu     = "host"

  # VM Memory Settings
  memory = 8192

  # VM Disk Settings
  cloudinit_cdrom_storage = "local-lvm" # needed to load the cloud-init drive
  disks {
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
    bridge = "vmbr0"
    model  = "virtio"
  }
  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # Credentials passed through cloud-init
  ciuser     = var.vm_username
  cipassword = var.vm_password

  # IP Address and Gateway (cloud-init)
  ipconfig0 = "ip=192.168.1.16${count.index + 3}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}
