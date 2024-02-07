# Proxmox Full-Clone
# ---
# Create a new VM from a clone

resource "proxmox_vm_qemu" "your-vm" {

  # VM General Settings
  target_node = "proxmox-01"
  vmid        = "200"
  name        = "vm-name"
  desc        = "Description"

  # VM Advanced General Settings
  onboot = true

  # VM OS Settings
  clone = "ubuntu-k8s-tmpl-01"

  # VM System Settings
  agent = 1

  # VM CPU Settings
  cores   = 1
  sockets = 1
  cpu     = "host"

  # VM Memory Settings
  memory = 1024

  # VM Network Settings
  network {
    bridge = "vmbr0"
    model  = "virtio"
  }

  # VM Cloud-Init Settings
  os_type = "cloud-init"

  # (Optional) IP Address and Gateway
  # ipconfig0 = "ip=0.0.0.0/0,gw=0.0.0.0"

  # (Optional) Default User
  # ciuser = "your-username"
  # cipassword = "your-password"

  # (Optional) Add your SSH KEY
  # sshkeys = <<EOF
  # #YOUR-PUBLIC-SSH-KEY
  # EOF
}
