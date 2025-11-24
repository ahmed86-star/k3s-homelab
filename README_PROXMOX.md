# Quick Start - Proxmox Deployment

Deploy K3s cluster on Proxmox with full automation!

## Prerequisites

- ✅ Proxmox VE running
- ✅ Ubuntu cloud image template created
- ✅ Terraform installed on Windows
- ✅ Network configured

## 1-Minute Setup

### Create Ubuntu Template (First Time Only)

SSH to Proxmox and run this script:

```bash
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
qm create 9000 --name ubuntu-2204-cloudinit-template --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm resize 9000 scsi0 20G
qm template 9000
```

### Configure & Deploy

1. **Edit Configuration**

```powershell
notepad terraform-proxmox.tfvars
```

Update these values:
```hcl
proxmox_host     = "https://YOUR-PROXMOX-IP:8006/api2/json"
proxmox_password = "your-proxmox-password"
ssh_password     = "your-vm-password"
```

2. **Deploy Everything**

```powershell
.\deploy-proxmox.ps1
```

That's it! Terraform will:
- Create 3 VMs on Proxmox
- Configure networking
- Install K3s
- Download kubeconfig

## Use Your Cluster

```powershell
$env:KUBECONFIG="$PWD\kubeconfig.yaml"
kubectl get nodes
```

## What Gets Created

| VM | IP | Role | ID |
|----|-------|------|----|
| k3s-master | 192.168.0.84 | Server | 300 |
| k3s-worker-1 | 192.168.0.235 | Agent | 301 |
| k3s-worker-2 | 192.168.0.115 | Agent | 302 |

## Troubleshooting

**"Template not found"** → Create the Ubuntu template (see above)

**"Connection failed"** → Check Proxmox credentials in `terraform-proxmox.tfvars`

**"Storage not found"** → Update `vm_storage` in config (run `pvesm status` on Proxmox)

## Full Documentation

See **[PROXMOX_DEPLOYMENT.md](PROXMOX_DEPLOYMENT.md)** for complete guide!

---

✨ **Enjoy your automated Kubernetes cluster!** ✨



