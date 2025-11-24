# Deployment Comparison Guide

Choose the best deployment method for your needs!

## 🎯 Quick Decision Guide

**Choose Proxmox Deployment if:**
- ✅ You want to learn full Infrastructure as Code
- ✅ You need reproducible infrastructure
- ✅ You want Terraform to manage everything
- ✅ You're building for a class project or portfolio
- ✅ You plan to rebuild the cluster multiple times

**Choose SSH-Only Deployment if:**
- ✅ You already have VMs running
- ✅ You want the simplest setup possible
- ✅ You just need K3s running quickly
- ✅ You're not concerned with VM provisioning
- ✅ You're testing or learning Kubernetes basics

## 📊 Feature Comparison

| Feature | Proxmox Deployment | SSH-Only Deployment |
|---------|-------------------|---------------------|
| **Creates VMs** | ✅ Automatic | ❌ Manual required |
| **VM Configuration** | ✅ Automated (cloud-init) | ❌ Manual required |
| **Networking Setup** | ✅ Automated | ❌ Manual required |
| **K3s Installation** | ✅ Automated | ✅ Automated |
| **Kubeconfig Download** | ✅ Automated | ✅ Automated |
| **Reproducibility** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Complexity** | 🔧🔧🔧 | 🔧 |
| **Setup Time** | 10-15 min (first time) | 5 min |
| **Prerequisites** | More (template, API) | Fewer (just VMs) |
| **Learning Value** | 🎓 High (Full IaC) | 🎓 Medium (K3s focus) |

## 🚀 Deployment Methods

### Option 1: Proxmox Full Automation

**What it does:**
```
Terraform → Creates 3 VMs on Proxmox
         → Configures networking (cloud-init)
         → Installs K3s on all nodes
         → Downloads kubeconfig
         → Verifies cluster
```

**Files to use:**
- `proxmox-main.tf` → Main Terraform config
- `proxmox-variables.tf` → Variable definitions
- `terraform-proxmox.tfvars` → Your configuration
- `deploy-proxmox.ps1` → Automated deployment

**Documentation:**
- **[PROXMOX_DEPLOYMENT.md](PROXMOX_DEPLOYMENT.md)** - Complete guide
- **[PROXMOX_SETUP.md](PROXMOX_SETUP.md)** - Setup instructions
- **[README_PROXMOX.md](README_PROXMOX.md)** - Quick reference

**Command:**
```powershell
.\deploy-proxmox.ps1
```

**Prerequisites:**
1. Proxmox VE running
2. Ubuntu cloud-init template created
3. Proxmox API access configured
4. Terraform installed

**Time to deploy:** ~8-10 minutes (first time with template creation)

---

### Option 2: SSH-Only Deployment

**What it does:**
```
Existing VMs → SSH connection
            → Install K3s on master
            → Get cluster token
            → Install K3s on workers
            → Download kubeconfig
```

**Files to use:**
- `main.tf` → Main Terraform config
- `variables.tf` → Variable definitions
- `terraform.tfvars` → Your configuration
- `setup-ssh.ps1` → Test connectivity

**Documentation:**
- **[QUICK_START.md](QUICK_START.md)** - Quick guide
- **[README.md](README.md)** - Full documentation
- **[WINDOWS_SSH_SETUP.md](WINDOWS_SSH_SETUP.md)** - SSH help

**Commands:**
```powershell
.\setup-ssh.ps1     # Test SSH
terraform init       # Initialize
terraform apply      # Deploy
```

**Prerequisites:**
1. 3 Ubuntu VMs already running
2. SSH access configured
3. Network connectivity
4. Terraform installed

**Time to deploy:** ~3-5 minutes

---

## 🔄 Switching Between Methods

### From SSH-Only to Proxmox

```powershell
# Backup current setup
Copy-Item main.tf main-ssh-only.tf.bak
Copy-Item variables.tf variables-ssh-only.tf.bak

# Switch to Proxmox
Copy-Item proxmox-main.tf main.tf
Copy-Item proxmox-variables.tf variables.tf
Copy-Item terraform-proxmox.tfvars terraform.tfvars

# Initialize with new provider
terraform init

# Deploy
.\deploy-proxmox.ps1
```

### From Proxmox to SSH-Only

```powershell
# Restore SSH-only config
Copy-Item main-ssh-only.tf.bak main.tf
Copy-Item variables-ssh-only.tf.bak variables.tf

# Or use the originals if not backed up
Copy-Item main.tf main-proxmox.tf.bak
Copy-Item variables.tf variables-proxmox.tf.bak

# Re-initialize
terraform init

# Deploy
terraform apply
```

## 📚 Learning Path Recommendation

### For Franklin University Cloud Engineering Students

**Week 1-2: Start with SSH-Only**
- Focus on Kubernetes concepts
- Learn kubectl commands
- Deploy applications
- Understand pods, services, deployments

**Week 3-4: Upgrade to Proxmox**
- Learn Infrastructure as Code
- Understand cloud-init
- Practice VM provisioning
- Build reproducible infrastructure

**Why this path?**
- ✅ Faster initial success (motivation!)
- ✅ Focus on one technology at a time
- ✅ Build complexity gradually
- ✅ Better understanding of each layer

## 💡 Use Case Examples

### SSH-Only is Great For:
- 🏃 "I need a K3s cluster for testing NOW"
- 📚 "I'm learning Kubernetes basics"
- 🔧 "I already have VMs set up"
- ⚡ "Quick demo for a presentation"

### Proxmox is Great For:
- 🎓 "I need to demonstrate IaC for class"
- 🔄 "I'll be rebuilding this cluster often"
- 📊 "I want full automation in my portfolio"
- 🏗️ "I'm learning DevOps practices"
- 🎯 "I want to understand the full stack"

## 🎓 Skills You'll Learn

### SSH-Only Deployment Skills:
- ✅ Terraform basics
- ✅ K3s installation
- ✅ Kubernetes cluster management
- ✅ SSH automation
- ✅ PowerShell scripting

### Proxmox Deployment Skills:
**Everything above, PLUS:**
- ✅ VM provisioning automation
- ✅ Cloud-init configuration
- ✅ Proxmox API usage
- ✅ Full Infrastructure as Code
- ✅ Complete environment automation

## 📊 Portfolio Value

### For Résumé/Portfolio:

**SSH-Only Deployment:**
- "Automated Kubernetes cluster deployment with Terraform"
- "Deployed K3s cluster using Infrastructure as Code"

**Proxmox Deployment:**
- "End-to-end infrastructure automation from VM creation to Kubernetes deployment"
- "Implemented full IaC stack: Proxmox + Terraform + K3s + cloud-init"
- "Automated infrastructure provisioning and application platform deployment"

## 🔧 Technical Differences

### Architecture

**SSH-Only:**
```
Windows Machine
    ↓ (terraform apply)
    ↓ (SSH commands)
    ↓
Existing VMs
    ↓ (curl | sh)
    ↓
K3s Installed
```

**Proxmox:**
```
Windows Machine
    ↓ (terraform apply)
    ↓ (Proxmox API)
    ↓
Proxmox Creates VMs
    ↓ (cloud-init)
    ↓
VMs Configured
    ↓ (SSH commands)
    ↓
K3s Installed
```

### State Management

**SSH-Only:**
- Terraform manages: K3s installation
- You manage: VMs, networking, storage

**Proxmox:**
- Terraform manages: VMs, networking, K3s, everything
- Proxmox manages: VM runtime

## 🎯 Recommendations

### For Your Situation (Proxmox with 3 existing VMs):

**Option A: Keep it Simple (Recommended for Now)**
Use SSH-Only deployment since your VMs are already configured:
```powershell
.\setup-ssh.ps1
terraform apply
```
✅ Fastest path to working cluster  
✅ VMs already match your configuration  
✅ Can switch to Proxmox later  

**Option B: Go Full Automation (Best for Learning)**
Destroy current VMs, create cloud-init template, use Proxmox deployment:
```powershell
.\deploy-proxmox.ps1
```
✅ Learn complete IaC workflow  
✅ Reproducible infrastructure  
✅ Better for portfolio/class projects  

### My Suggestion:
**Start with SSH-Only** (working cluster in 5 min), then **upgrade to Proxmox** once comfortable (better learning experience).

---

## 📖 Next Steps

Choose your path:

### Path A: SSH-Only (Quick Start)
1. Read [QUICK_START.md](QUICK_START.md)
2. Run `.\setup-ssh.ps1`
3. Run `terraform apply`
4. Start learning Kubernetes!

### Path B: Proxmox (Full IaC)
1. Read [PROXMOX_SETUP.md](PROXMOX_SETUP.md)
2. Create Ubuntu template
3. Run `.\deploy-proxmox.ps1`
4. Explore full automation!

---

**Questions?** Check the specific documentation for your chosen method!



