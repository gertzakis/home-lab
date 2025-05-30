# Proxmox VMs
# ---
# Create VMs cloned from a cloud-init template

# Create a Proxmox pool for Kubernetes VMs
resource "proxmox_pool" "k8s-cluster" {
  poolid  = "k8s-cluster"
  comment = "Kubernetes Cluster VMs"
}

# Create Kubernetes Master nodes
resource "proxmox_vm_qemu" "kubernetes-masters" {
  depends_on = [ proxmox_pool.k8s-cluster ]
  count = 1

  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "16${count.index}"
  name        = "k8s-master-0${count.index + 1}"
  desc        = "Kubernetes master node ${count.index + 1} \n\n IP `192.168.1.16${count.index}`"
  pool        = "k8s-cluster"
  tags        = "k8s;master" # comma seperated format

  # VM OS Settings
  clone   = "ubuntu-k8s-tmpl-01"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  sockets = 1
  cores   = 2
  cpu_type     = "host"

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
  ipconfig0 = "ip=192.168.1.16${count.index}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}

# Create Kubernetes Worker nodes
resource "proxmox_vm_qemu" "kubernetes-workers" {
  depends_on = [ proxmox_pool.k8s-cluster ]
  count = 3

  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "16${count.index + 3}"
  name        = "k8s-worker-0${count.index + 1}"
  desc        = "Kubernetes worker node ${count.index + 1} \n\n IP `192.168.1.16${count.index + 3}`"
  pool        = "k8s-cluster"
  tags        = "k8s;worker" # comma seperated format

  # VM OS Settings
  clone   = "ubuntu-k8s-tmpl-01"
  qemu_os = "other"
  agent   = 1 # Installing agent through cloud-init

  # VM CPU Settings
  sockets = 1
  cores   = 2
  cpu_type     = "host"

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
  ipconfig0 = "ip=192.168.1.16${count.index + 3}/24,gw=192.168.1.1"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}
