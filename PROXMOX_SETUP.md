# Proxmox Setup Guide for K3s Deployment

This guide will help you prepare Proxmox for automated VM provisioning with Terraform.

## 📋 Prerequisites

- Proxmox VE 7.x or 8.x installed and running
- Access to Proxmox web interface
- Internet connection on Proxmox host
- Windows machine with Terraform installed

## 🎯 Overview

We'll create:
1. Ubuntu 22.04 Cloud-Init template
2. Proxmox API credentials
3. Network configuration

## Part 1: Create Ubuntu Cloud-Init Template

### Step 1: Download Ubuntu Cloud Image

SSH into your Proxmox host and run:

```bash
# SSH to Proxmox
ssh root@YOUR-PROXMOX-IP

# Navigate to template storage
cd /var/lib/vz/template/iso

# Download Ubuntu 22.04 Cloud Image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Verify download
ls -lh jammy-server-cloudimg-amd64.img
```

### Step 2: Create VM Template

```bash
# Create a new VM (ID 9000)
qm create 9000 --name ubuntu-2204-cloudinit-template --memory 2048 --net0 virtio,bridge=vmbr0

# Import the cloud image as a disk
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm

# Attach the disk to the VM
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0

# Add cloud-init drive
qm set 9000 --ide2 local-lvm:cloudinit

# Set boot disk
qm set 9000 --boot c --bootdisk scsi0

# Add serial console
qm set 9000 --serial0 socket --vga serial0

# Enable QEMU guest agent
qm set 9000 --agent enabled=1

# Resize disk (optional - increase from default 2GB to 20GB)
qm resize 9000 scsi0 20G

# Convert to template
qm template 9000

echo "Template created successfully!"
```

### Step 3: Verify Template

In Proxmox web UI:
1. Navigate to your node
2. Look for VM 9000 named "ubuntu-2204-cloudinit-template"
3. It should show a template icon 📋

## Part 2: Create Proxmox API Token

### Option A: Use Root Password (Quick Start)

Simply use `root@pam` and your root password in `terraform-proxmox.tfvars`.

### Option B: Create API Token (Recommended for Production)

1. **Login to Proxmox Web UI**
   - Go to: `https://YOUR-PROXMOX-IP:8006`

2. **Create User (Optional - if not using root)**
   - Datacenter → Permissions → Users → Add
   - Username: `terraform`
   - Realm: `pam`
   - Password: Set a strong password

3. **Create API Token**
   - Datacenter → Permissions → API Tokens → Add
   - User: `root@pam` (or your terraform user)
   - Token ID: `terraform`
   - **Uncheck** "Privilege Separation"
   - Click Add
   - **IMPORTANT**: Copy the secret immediately (it's shown only once!)

4. **Set Permissions**
   - Datacenter → Permissions → Add → User Permission
   - Path: `/`
   - User: `root@pam` (or terraform@pam)
   - Role: `Administrator`

## Part 3: Configure Network

### Check Your Network Settings

1. In Proxmox UI, go to: Node → System → Network
2. Note your bridge name (usually `vmbr0`)
3. Note your gateway IP (e.g., `192.168.0.1`)

### Verify IP Addresses Are Available

Make sure these IPs are available on your network:
- `192.168.0.84` - Master node
- `192.168.0.235` - Worker 1
- `192.168.0.115` - Worker 2

You can check with:

```bash
# From Proxmox host
ping -c 2 192.168.0.84
ping -c 2 192.168.0.235
ping -c 2 192.168.0.115
```

If they respond, those IPs are in use. Choose different IPs if needed.

## Part 4: Configure Terraform

### 1. Update terraform-proxmox.tfvars

Edit `terraform-proxmox.tfvars`:

```hcl
# Proxmox Configuration
proxmox_host     = "https://YOUR-PROXMOX-IP:8006/api2/json"
proxmox_node     = "pve"  # or your node name
proxmox_user     = "root@pam"
proxmox_password = "your-proxmox-password"

# VM Template
vm_template = "ubuntu-2204-cloudinit-template"
vm_storage  = "local-lvm"  # or your storage name

# Network
network_bridge  = "vmbr0"
network_gateway = "192.168.0.1"

# SSH Credentials
ssh_user     = "ahmed1"
ssh_password = "your-vm-password"

# Node IPs
master_ip = "192.168.0.84"
worker_ips = ["192.168.0.235", "192.168.0.115"]
```

### 2. Test Proxmox Connection

Create a test script `test-proxmox.ps1`:

```powershell
# Test Proxmox API Connection
$proxmoxHost = "https://YOUR-PROXMOX-IP:8006/api2/json"
$user = "root@pam"
$password = "your-password"

$body = @{
    username = $user
    password = $password
}

try {
    $response = Invoke-RestMethod -Uri "$proxmoxHost/access/ticket" -Method Post -Body $body -SkipCertificateCheck
    Write-Host "✓ Proxmox connection successful!" -ForegroundColor Green
    Write-Host "Ticket received: $($response.data.ticket.Substring(0,20))..." -ForegroundColor Green
} catch {
    Write-Host "✗ Connection failed: $($_.Exception.Message)" -ForegroundColor Red
}
```

Run it:

```powershell
.\test-proxmox.ps1
```

## Part 5: Deploy with Terraform

### Use Proxmox Configuration

```powershell
# Backup existing files (if you were using the SSH-only version)
Move-Item main.tf main-ssh-only.tf.bak
Move-Item variables.tf variables-ssh-only.tf.bak

# Use Proxmox configuration
Copy-Item proxmox-main.tf main.tf
Copy-Item proxmox-variables.tf variables.tf
Copy-Item terraform-proxmox.tfvars terraform.tfvars

# Initialize Terraform with Proxmox provider
terraform init

# Validate configuration
terraform validate

# Preview changes
terraform plan

# Deploy!
terraform apply
```

This will:
1. ✅ Create 3 VMs on Proxmox
2. ✅ Configure them with cloud-init
3. ✅ Install K3s on all nodes
4. ✅ Download kubeconfig

## 🔧 Troubleshooting

### "Could not connect to Proxmox API"

- Check Proxmox is accessible: `https://YOUR-IP:8006`
- Verify credentials in `terraform-proxmox.tfvars`
- Check firewall isn't blocking port 8006

### "Template not found"

```bash
# On Proxmox, list templates
qm list | grep template

# If missing, recreate template (see Step 2 above)
```

### "Storage 'local-lvm' does not exist"

```bash
# List available storage
pvesm status

# Update terraform-proxmox.tfvars with correct storage name
```

### "IP address already in use"

- Choose different IPs in `terraform-proxmox.tfvars`
- Or remove conflicting VMs in Proxmox

### Cloud-init not working

```bash
# Check if qemu-guest-agent is installed in template
qm agent 9000 ping

# If not working, install in template before converting:
apt update && apt install -y qemu-guest-agent
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent
```

## 📚 Additional Resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Cloud-Init Documentation](https://cloudinit.readthedocs.io/)
- [Terraform Proxmox Provider](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)

## 🎯 Quick Reference

### Useful Proxmox Commands

```bash
# List all VMs
qm list

# Check VM status
qm status <VMID>

# Start VM
qm start <VMID>

# Stop VM
qm stop <VMID>

# Delete VM
qm destroy <VMID>

# View VM config
qm config <VMID>

# Clone template
qm clone 9000 100 --name new-vm --full
```

### Terraform Commands

```powershell
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Destroy all
terraform destroy

# Destroy specific resource
terraform destroy -target=proxmox_vm_qemu.k3s_master
```

---

**Ready to deploy?** Make sure you've completed all steps, then run `terraform apply`! 🚀



