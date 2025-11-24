# Project Structure

Complete overview of all files in this K3s Homelab project.

## 📄 Documentation Files

| File | Purpose |
|------|---------|
| **README.md** | Main project documentation with full deployment guide |
| **QUICK_START.md** | 5-minute quick deployment guide |
| **WINDOWS_SSH_SETUP.md** | Windows-specific SSH configuration help |
| **PROJECT_STRUCTURE.md** | This file - overview of the project |
| **LICENSE** | Project license |

## 🔧 Terraform Configuration Files

| File | Purpose |
|------|---------|
| **main.tf** | Main Terraform configuration - deploys K3s cluster |
| **variables.tf** | Variable definitions for cluster configuration |
| **outputs.tf** | Output definitions for cluster information |
| **terraform.tfvars** | Your configuration values (⚠️ contains password) |

## 🛠️ Helper Scripts (PowerShell)

| File | Purpose |
|------|---------|
| **setup-ssh.ps1** | Test SSH connectivity to all nodes |
| **verify-cluster.ps1** | Verify cluster health after deployment |
| **destroy-cluster.ps1** | Safely destroy the entire cluster |

## 📁 Generated Files (After Deployment)

These files are created when you run `terraform apply`:

| File | Purpose |
|------|---------|
| **kubeconfig.yaml** | Kubernetes cluster credentials for kubectl |
| **k3s-token.txt** | K3s cluster join token |
| **terraform.tfstate** | Terraform state file (managed automatically) |
| **terraform.tfstate.backup** | Backup of previous state |
| **.terraform/** | Terraform provider plugins directory |
| **.terraform.lock.hcl** | Terraform dependency lock file |

⚠️ **IMPORTANT:** Generated files contain sensitive data and are excluded in `.gitignore`

## 🔒 Security Files

| File | Purpose |
|------|---------|
| **.gitignore** | Prevents sensitive files from being committed to Git |

## 📊 Workflow Overview

```
1. Review:          README.md or QUICK_START.md
2. Test SSH:        .\setup-ssh.ps1
3. Configure:       Edit terraform.tfvars (add password)
4. Initialize:      terraform init
5. Deploy:          terraform apply
6. Verify:          .\verify-cluster.ps1
7. Use:             kubectl get nodes
8. (Optional) Destroy:  .\destroy-cluster.ps1
```

## 🎯 File Categories

### Must Edit
- `terraform.tfvars` - Add your SSH password

### Don't Commit to Git
- `terraform.tfvars` - Contains password
- `kubeconfig.yaml` - Cluster credentials
- `k3s-token.txt` - Join token
- `*.tfstate*` - Terraform state
- `.terraform/` - Provider files

### Read for Help
- `README.md` - Full documentation
- `QUICK_START.md` - Quick guide
- `WINDOWS_SSH_SETUP.md` - SSH help

### Run When Needed
- `setup-ssh.ps1` - Before deployment
- `verify-cluster.ps1` - After deployment
- `destroy-cluster.ps1` - To clean up

## 🔄 Typical Deployment Flow

### First Time Setup
```powershell
# 1. Check SSH connectivity
.\setup-ssh.ps1

# 2. Edit terraform.tfvars with your password
notepad terraform.tfvars

# 3. Initialize Terraform
terraform init

# 4. Deploy cluster
terraform apply

# 5. Verify deployment
.\verify-cluster.ps1

# 6. Use your cluster
$env:KUBECONFIG="$PWD\kubeconfig.yaml"
kubectl get nodes
```

### Daily Use
```powershell
# Set kubeconfig
$env:KUBECONFIG="$PWD\kubeconfig.yaml"

# Work with your cluster
kubectl get nodes
kubectl get pods -A
kubectl create deployment nginx --image=nginx
```

### Cleanup
```powershell
# Destroy cluster
.\destroy-cluster.ps1

# Or use Terraform
terraform destroy
```

## 📦 Technology Stack

- **Infrastructure**: Proxmox VMs
- **Operating System**: Ubuntu Server 22.04
- **Kubernetes**: K3s (Lightweight Kubernetes)
- **IaC Tool**: Terraform
- **Configuration**: PowerShell scripts
- **Local OS**: Windows 10/11

## 🎓 Learning Resources

Each file serves an educational purpose:

- **Terraform files**: Learn Infrastructure as Code
- **PowerShell scripts**: Learn automation and scripting
- **K3s deployment**: Learn Kubernetes architecture
- **Documentation**: Learn technical writing

## 🤝 Contributing

To extend this project:

1. Add new Terraform resources in `main.tf`
2. Add new variables in `variables.tf`
3. Update documentation in README files
4. Create new helper scripts as needed
5. Keep `.gitignore` updated for new sensitive files

## 📞 Support

Having issues? Check:

1. **README.md** - Troubleshooting section
2. **WINDOWS_SSH_SETUP.md** - SSH issues
3. **QUICK_START.md** - Common problems
4. Run `.\verify-cluster.ps1` to diagnose issues

---

**Happy clustering!** 🚀

