source "proxmox-iso" "ubuntu-24_04" {
  proxmox_url               = "${var.proxmox_api_url}"
  username                  = "${var.proxmox_api_token_id}"
  token                     = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify  = true

  node                 = "proxmox-01"
  vm_id                = "90103"
  vm_name              = "ubuntu-24-04-tmpl-01.home.lab"
  template_description = "A minimal Ubuntu 24.04 template with cloud-init."

  iso_file         = "local:iso/ubuntu-24.04.4-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true
  qemu_agent       = true

  scsi_controller = "virtio-scsi-pci"

  cores   = "1"
  sockets = "1"
  memory  = "2048"

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  # Cloud-init config via additional ISO
  additional_iso_files {
    type              = "ide"
    index             = 1
    iso_storage_pool  = "local"
    unmount           = true
    keep_cdrom_device = false
    cd_files = [
      "./ubuntu-24_04/http/meta-data",
      "./ubuntu-24_04/http/user-data"
    ]
    cd_label = "cidata"
  }

  vga {
    type = "virtio"
  }

  disks {
    disk_size    = "20G"
    format       = "raw"
    storage_pool = "local-lvm"
    type         = "virtio"
  }

  network_adapters {
    model    = "virtio"
    bridge   = "vmbr0"
    firewall = "false"
  }

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall quiet ds=nocloud",
    "<f10><wait>",
    "<wait3m>",
    "yes<enter>"
  ]

  boot         = "c"
  boot_wait    = "6s"
  communicator = "ssh"

  ssh_username  = "${var.ssh_username}"
  ssh_password  = "${var.ssh_password}"

  # Raise the timeout, when installation takes longer
  ssh_timeout            = "30m"
  ssh_pty                = true
  ssh_handshake_attempts = 15
}

build {

  name = "pkr-ubuntu-noble-1"
  sources = [
    "source.proxmox-iso.ubuntu-24_04"
  ]

  # Waiting for Cloud-Init to finish (may be disabled after autoinstall in 24.04)
  provisioner "shell" {
    inline = ["sudo cloud-init status --wait || true"]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
  provisioner "shell" {
    execute_command = "echo -e '<user>' | sudo -S -E bash '{{ .Path }}'"
    inline = [
      "echo 'Starting Stage: Provisioning the VM Template for Cloud-Init Integration in Proxmox'",
      "sudo rm /etc/ssh/ssh_host_*",
      "sudo truncate -s 0 /etc/machine-id",
      "sudo apt -y autoremove --purge",
      "sudo apt -y clean",
      "sudo apt -y autoclean",
      "sudo cloud-init clean --logs",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo cloud-init init --local || true",
      "sudo sync",
      "echo 'Done Stage: Provisioning the VM Template for Cloud-Init Integration in Proxmox'"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "ubuntu-24_04/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }
}
