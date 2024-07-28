# home-lab

This is my personal Home lab. Just a mini PC with some extra RAM that's running Proxmox.

<img src="https://cdn.worldvectorlogo.com/logos/proxmox.svg" alt="Proxmox Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/packer/packer-original.svg" alt="Packer Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/terraform/terraform-original.svg" alt="Terraform Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/kubernetes/kubernetes-original.svg" alt="Kubernetes Logo" width="50" height="50"/>

I use Packer and OpenTofu to manage the infra (VMs)

The infra though is just a Kubernetes cluster, and you can find the configuration of reasources under `kubernetes` directory. Keep in mind GitOps with `FluxCD` is used to provision anything inside the cluster, and I try to force myself going down that path ;)
