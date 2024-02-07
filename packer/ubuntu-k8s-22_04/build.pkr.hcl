source "proxmox-iso" "ubuntu-22_04" {
  proxmox_url              = "${var.proxmox_api_url}"
  username                 = "${var.proxmox_api_token_id}"
  token                    = "${var.proxmox_api_token_secret}"
  insecure_skip_tls_verify = true

  node                 = "proxmox-01"
  vm_id                = "90102"
  vm_name              = "ubuntu-k8s-tmpl-01"
  template_description = "A Ubuntu 22.04 cloud-init enabled template, ready for Kubernetes 1.29."

  iso_file         = "local:iso/ubuntu-22.04.3-live-server-amd64.iso"
  iso_storage_pool = "local"
  unmount_iso      = true
  qemu_agent       = true

  scsi_controller = "virtio-scsi-pci"

  cores   = "2"
  sockets = "2"
  memory  = "4096"

  cloud_init              = true
  cloud_init_storage_pool = "local-lvm"

  vga {
    type = "virtio"
  }

  disks {
    disk_size    = "30G"
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
    "<bs><bs><bs><bs><wait>",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]

  boot         = "c"
  boot_wait    = "6s"
  communicator = "ssh"

  http_directory    = "ubuntu-k8s-22_04/http"
  http_bind_address = "${var.http_server_address}"

  ssh_username = "${var.ssh_username}"
  ssh_password = "${var.ssh_password}"

  # Raise the timeout, when installation takes longer
  ssh_timeout            = "30m"
  ssh_pty                = true
  ssh_handshake_attempts = 15
}

build {

  name = "pkr-ubuntu-jammy-1"
  sources = [
    "source.proxmox-iso.ubuntu-22_04"
  ]

  # Waiting for Cloud-Init to finish
  provisioner "shell" {
    inline = ["cloud-init status --wait"]
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
      "sudo cloud-init clean",
      "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
      "sudo rm -f /etc/netplan/00-installer-config.yaml",
      "sudo sync",
      "echo 'Done Stage: Provisioning the VM Template for Cloud-Init Integration in Proxmox'"
    ]
  }

  # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
  provisioner "file" {
    source      = "ubuntu-k8s-22_04/files/99-pve.cfg"
    destination = "/tmp/99-pve.cfg"
  }
  provisioner "shell" {
    inline = ["sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg"]
  }

  # Disable swap
  provisioner "shell" {
    inline = [
      "sudo swapoff -a",
      "sudo sed -i '/swap/ s/^/#/' /etc/fstab"
    ]
  }

  # Add kernel parameters
  provisioner "shell" {
    inline = [
      "sudo tee /etc/modules-load.d/containerd.conf <<EOF",
      "overlay",
      "br_netfilter",
      "EOF",
      "sudo modprobe overlay",
      "sudo modprobe br_netfilter"
    ]
  }

  # Configure Kubernetes related kernel parameters
  provisioner "shell" {
    inline = [
      "sudo tee /etc/sysctl.d/kubernetes.conf <<EOF",
      "net.bridge.bridge-nf-call-ip6tables = 1",
      "net.bridge.bridge-nf-call-iptables = 1",
      "net.ipv4.ip_forward = 1",
      "EOF",
      "sudo sysctl --system"
    ]
  }

  # Install containerd & docker, also configure containerd runtime to use systemd as cgroup
  provisioner "shell" {
    inline = [
      "sudo apt-get remove -y needrestart", # TODO, needs to be revised with `DEBIAN_FRONTEND=noninteractive` or other envs
      "sudo apt-get update",
      "sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates gpg",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update",
      "while lsof /var/lib/dpkg/lock-frontend ; do sleep 10; done;",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1",
      "sudo sed -i 's/SystemdCgroup \\= false/SystemdCgroup \\= true/g' /etc/containerd/config.toml",
      "sudo systemctl restart containerd",
      "sudo systemctl enable containerd"
    ]
  }

  # Install k8s stuff (kubectl, kubeadm, kubelet) to be ready for provisioning a Kubernetes cluster
  provisioner "shell" {
    inline = [
      "curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg",
      "echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list",
      "sudo apt update",
      "while lsof /var/lib/dpkg/lock-frontend ; do sleep 10; done;",
      "sudo apt install -y kubelet kubeadm kubectl",
      "sudo apt-mark hold kubelet kubeadm kubectl"
    ]
  }
}
