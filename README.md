# home-lab

This is my personal Home lab. Just a mini PC with some extra RAM that's running Proxmox.

<img src="https://cdn.worldvectorlogo.com/logos/proxmox.svg" alt="Proxmox Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/packer/packer-original.svg" alt="Packer Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/terraform/terraform-original.svg" alt="Terraform Logo" width="50" height="50"/> <img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/kubernetes/kubernetes-original.svg" alt="Kubernetes Logo" width="50" height="50"/>

I use Packer and OpenTofu to manage the infra (VMs)

The infra though is just a Kubernetes cluster, and you can find the configuration of reasources under `kubernetes` directory. Keep in mind GitOps with `FluxCD` is used to provision anything inside the cluster, and I try to force myself going down that path ;)

## Crypto

In order to store sensitive information in this repo I use [sops](https://github.com/getsops/sops). You can find the public cryptographic key to encrypt under kubernetes/clusters/home-lab/.

Follow the below example when you operate on stdin.

```bash
sops encrypt --input-type yaml packer/ubuntu-22_04/http/user-data --output-type yaml > packer/ubuntu-22_04/http/user-data.enc
cat packer/ubuntu-22_04/http/user-data.enc | sops decrypt --input-type yaml --output-type yaml /dev/stdin
```
