# K3s Deployment on Proxmox - Complete Guide

Automated deployment of K3s Kubernetes cluster with Terraform on Proxmox VE.

## 🎯 What This Does

This deployment will:
1. **Create 3 VMs** on your Proxmox server automatically
2. **Configure networking** with static IPs via cloud-init
3. **Install K3s** on all nodes (1 master + 2 workers)
4. **Download kubeconfig** to your Windows machine
5. **Give you a ready-to-use Kubernetes cluster**

## 📋 Prerequisites

### On Proxmox Server
- [x] Proxmox VE 7.x or 8.x running
- [x] Ubuntu 22.04 Cloud-Init template created ([see guide](#create-template))
- [x] API access configured (username/password or token)
- [x] Network bridge configured (usually `vmbr0`)
- [x] Storage available (at least 60GB for 3 VMs)

### On Your Windows Machine
- [x] Terraform installed (`choco install terraform`)
- [x] SSH client available (built-in on Windows 10/11)
- [x] Network access to Proxmox

## 🚀 Quick Deployment (5 Minutes)

### Step 1: Create Ubuntu Template on Proxmox

**First time only!** SSH to Proxmox and run:

```bash
# Download Ubuntu cloud image
cd /var/lib/vz/template/iso
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create template (VM ID 9000)
qm create 9000 --name ubuntu-2204-cloudinit-template --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm resize 9000 scsi0 20G
qm template 9000

echo "✓ Template created!"
```

### Step 2: Configure Terraform

Edit `terraform-proxmox.tfvars`:

```hcl
# Proxmox Connection
proxmox_host     = "https://YOUR-PROXMOX-IP:8006/api2/json"
proxmox_node     = "pve"
proxmox_user     = "root@pam"
proxmox_password = "your-proxmox-password"

# Template & Storage
vm_template = "ubuntu-2204-cloudinit-template"
vm_storage  = "local-lvm"

# Network
network_bridge  = "vmbr0"
network_gateway = "192.168.0.1"

# SSH for VMs
ssh_user     = "ahmed1"
ssh_password = "your-vm-password"

# IP Addresses
master_ip = "192.168.0.84"
worker_ips = ["192.168.0.235", "192.168.0.115"]
```

### Step 3: Deploy Everything

Run the automated deployment script:

```powershell
.\deploy-proxmox.ps1
```

Or manually:

```powershell
# Initialize
terraform init

# Preview
terraform plan

# Deploy
terraform apply
```

Type `yes` when prompted.

### Step 4: Use Your Cluster

```powershell
# Set kubeconfig
$env:KUBECONFIG="$PWD\kubeconfig.yaml"

# Check nodes
kubectl get nodes

# Deploy something
kubectl create deployment nginx --image=nginx
```

## 📁 What Gets Created on Proxmox

| VM ID | Name | IP | Role | Specs |
|-------|------|-------|------|-------|
| 300 | k3s-master | 192.168.0.84 | K3s Server | 2 CPU, 2GB RAM, 20GB Disk |
| 301 | k3s-worker-1 | 192.168.0.235 | K3s Agent | 2 CPU, 2GB RAM, 20GB Disk |
| 302 | k3s-worker-2 | 192.168.0.115 | K3s Agent | 2 CPU, 2GB RAM, 20GB Disk |

## 🔧 Configuration Options

### Customize VM Resources

Edit `terraform-proxmox.tfvars`:

```hcl
vm_cores     = 4      # CPU cores per VM
vm_memory    = 4096   # RAM in MB per VM
vm_disk_size = "30G"  # Disk size per VM
```

### Change VM IDs

```hcl
master_vm_id  = 400
worker1_vm_id = 401
worker2_vm_id = 402
```

### Use Different IPs

```hcl
master_ip = "192.168.1.10"
worker_ips = [
  "192.168.1.11",
  "192.168.1.12"
]
network_gateway = "192.168.1.1"
```

### Use API Token Instead of Password

More secure for production:

1. Create token in Proxmox UI:
   - Datacenter → Permissions → API Tokens → Add
   - User: `root@pam`, Token ID: `terraform`
   - Uncheck "Privilege Separation"

2. Update `terraform-proxmox.tfvars`:

```hcl
# Comment out password
# proxmox_password = "..."

# Use token instead
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## 🐛 Troubleshooting

### "Could not connect to Proxmox API"

**Cause**: Proxmox is unreachable or credentials are wrong

**Solution**:
```powershell
# Test Proxmox web UI
Start-Process "https://YOUR-PROXMOX-IP:8006"

# Verify credentials in terraform-proxmox.tfvars
```

### "Template 'ubuntu-2204-cloudinit-template' not found"

**Cause**: VM template wasn't created

**Solution**: See [Step 1: Create Ubuntu Template](#step-1-create-ubuntu-template-on-proxmox)

```bash
# On Proxmox, check templates
qm list | grep template
```

### "Storage 'local-lvm' does not exist"

**Cause**: Storage name is different in your Proxmox

**Solution**:
```bash
# On Proxmox, list storage
pvesm status

# Update terraform-proxmox.tfvars with correct storage name
vm_storage = "your-storage-name"
```

### "IP address already in use"

**Cause**: Another VM is using those IPs

**Solution**: Choose different IPs in `terraform-proxmox.tfvars`

```powershell
# Test if IP is free
ping 192.168.0.84
# If it responds, the IP is taken
```

### VMs Created But K3s Installation Fails

**Cause**: SSH not working or cloud-init issue

**Solution**:
```bash
# SSH to master manually
ssh ahmed1@192.168.0.84

# Check cloud-init status
cloud-init status

# Check if qemu-guest-agent is running
systemctl status qemu-guest-agent
```

### "timeout while waiting for the machine to boot"

**Cause**: VMs taking too long to start

**Solution**: Increase timeout or check VM in Proxmox console

```bash
# On Proxmox, check VM console
qm terminal <VMID>
```

## 🔄 Deployment Workflow

```
1. Proxmox Template Created ──────┐
                                  ▼
2. Configure terraform-proxmox.tfvars
                                  ▼
3. terraform init (download providers)
                                  ▼
4. terraform apply ───────┬──────▶ Create VM 300 (master)
                          ├──────▶ Create VM 301 (worker-1)
                          └──────▶ Create VM 302 (worker-2)
                                  ▼
5. Wait for VMs to boot (60 seconds)
                                  ▼
6. Install K3s on master ────────▶ Get cluster token
                                  ▼
7. Install K3s on workers ───────▶ Join cluster
                                  ▼
8. Download kubeconfig ──────────▶ Ready to use!
```

## 🎓 Advanced Topics

### Add More Worker Nodes

1. Update `terraform-proxmox.tfvars`:

```hcl
worker_ips = [
  "192.168.0.235",
  "192.168.0.115",
  "192.168.0.120"  # New worker
]

worker3_vm_id = 303
```

2. Add worker resource in `proxmox-main.tf` (copy worker_2 block)

3. Run `terraform apply`

### Use Different Ubuntu Versions

```bash
# On Proxmox, download different version
wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img

# Create template with different ID
qm create 9001 --name ubuntu-2004-cloudinit-template ...
```

Update `terraform-proxmox.tfvars`:
```hcl
vm_template = "ubuntu-2004-cloudinit-template"
```

### SSH Key Authentication

More secure than password:

```powershell
# Generate SSH key
ssh-keygen -t ed25519 -f k3s-cluster -C "k3s-homelab"

# Add public key to terraform-proxmox.tfvars
$pubkey = Get-Content k3s-cluster.pub -Raw
# Copy the key and update:
```

```hcl
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZ... k3s-homelab"
```

## 📊 Resource Usage

Per default configuration (3 VMs):

- **CPU**: 6 cores total (2 per VM)
- **RAM**: 6GB total (2GB per VM)
- **Disk**: 60GB total (20GB per VM)
- **Network**: 1 IP per VM

## 🗑️ Cleanup & Removal

### Remove Everything

```powershell
# Use the destroy script
.\destroy-cluster.ps1

# Or manually
terraform destroy
```

This will:
1. Uninstall K3s from all nodes
2. Delete all VMs from Proxmox (IDs 300, 301, 302)
3. Clean up local files
4. Remove Terraform state

### Remove Only K3s (Keep VMs)

```bash
# SSH to each node and run:
sudo /usr/local/bin/k3s-uninstall.sh        # On master
sudo /usr/local/bin/k3s-agent-uninstall.sh  # On workers
```

## 📚 Related Documentation

- **[PROXMOX_SETUP.md](PROXMOX_SETUP.md)** - Detailed Proxmox setup guide
- **[README.md](README.md)** - Original SSH-only deployment
- **[QUICK_START.md](QUICK_START.md)** - Quick deployment guide

## 🆚 Proxmox vs SSH-Only Deployment

| Feature | Proxmox Deployment | SSH-Only Deployment |
|---------|-------------------|---------------------|
| **VMs Created** | ✅ Automatic | ❌ Manual |
| **Full IaC** | ✅ Yes | ⚠️ Partial |
| **Reproducible** | ✅ 100% | ⚠️ 95% |
| **Complexity** | ⚠️ More setup | ✅ Simple |
| **Use Case** | Production/Learning IaC | Quick homelab |

## 🎉 Success Checklist

After deployment, you should have:

- [x] 3 VMs visible in Proxmox UI
- [x] All VMs showing as "running"
- [x] `kubeconfig.yaml` file created locally
- [x] `kubectl get nodes` shows 3 nodes
- [x] All nodes status is "Ready"
- [x] System pods running (`kubectl get pods -A`)

---

**Questions?** See [PROXMOX_SETUP.md](PROXMOX_SETUP.md) for detailed troubleshooting!



