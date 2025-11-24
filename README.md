# K3s Homelab - Terraform Automation

This repository contains Terraform configuration to automatically provision a lightweight Kubernetes cluster using K3s. It creates a cluster with one master node and two worker nodes, all running Ubuntu Server.

## 🎯 Goals

**Reproducibility** is the primary goal, achieved through:

- **Infrastructure as Code (IaC)** using Terraform to manage cluster deployment
- **Automated configuration** to consistently deploy K3s across all nodes
- **Version control** for all infrastructure definitions

## 🏗️ Architecture

The infrastructure consists of:

- **1 K3s master node** - Control plane running K3s server
- **2 K3s worker nodes** - Worker nodes running K3s agents
- **Static IP addressing** for reliable cluster networking
- **Ubuntu Server 22.04 LTS** on all nodes

### Example Setup

```
Master Node:  192.168.1.10  (k3s-master)
Worker Node 1: 192.168.1.11  (k3s-worker-1)
Worker Node 2: 192.168.1.12  (k3s-worker-2)
```

## 📋 Prerequisites

Before you begin, ensure you have:

- [ ] 3 Ubuntu Server 22.04 VMs running (or Proxmox VE for automated provisioning)
- [ ] SSH access to all nodes with your username
- [ ] Terraform installed locally (v1.0+)
- [ ] kubectl installed for cluster management
- [ ] Network connectivity between all nodes
- [ ] SSH key pair for authentication (recommended)

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/YOUR_USERNAME/k3s-homelab.git
cd k3s-homelab
```

### 2. Configure Variables

Copy the example configuration and edit with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Edit with your specific configuration:

```hcl
ssh_user     = "your-username"
ssh_password = "your-secure-password"

master_ip = "192.168.1.10"
worker_ips = [
  "192.168.1.11",
  "192.168.1.12"
]

k3s_version = "v1.28.5+k3s1"
```

⚠️ **IMPORTANT:** Never commit `terraform.tfvars` - it's protected by `.gitignore`

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Deploy K3s Cluster

```bash
terraform apply
```

Type `yes` when prompted. This will:

1. Install K3s server on the master node
2. Retrieve the cluster join token
3. Install K3s agents on worker nodes
4. Join workers to the cluster
5. Download kubeconfig to your local machine

### 6. Access Your Cluster

```bash
# Set kubeconfig environment variable
export KUBECONFIG="$PWD/kubeconfig.yaml"

# Verify cluster is ready
kubectl get nodes

# Check system pods
kubectl get pods -A
```

You should see all 3 nodes in `Ready` state!

## 🔧 What Gets Installed

- **K3s server** on master node (control plane)
- **K3s agents** on worker nodes
- **Traefik disabled** (you can add your own ingress controller)
- **ServiceLB disabled** (MetalLB can be added for load balancing)
- **Systemd services** for automatic startup
- **Kubeconfig** downloaded locally for kubectl access

## 📁 Generated Files

After running `terraform apply`:

| File | Description |
|------|-------------|
| `kubeconfig.yaml` | Your cluster credentials (use with kubectl) |
| `k3s-token.txt` | Cluster join token |
| `terraform.tfstate` | Terraform state (managed automatically) |

⚠️ **These files are automatically excluded from Git** via `.gitignore`

## 🎯 Post-Deployment

### Verify Cluster Health

```bash
# Check all nodes
kubectl get nodes -o wide

# Verify system pods are running
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info

# View node details
kubectl describe nodes
```

### Deploy Your First Application

```bash
# Deploy nginx
kubectl create deployment nginx --image=nginx

# Expose it as a service
kubectl expose deployment nginx --port=80 --type=NodePort

# Check the service
kubectl get svc nginx

# Get the NodePort
kubectl get svc nginx -o jsonpath='{.spec.ports[0].nodePort}'

# Access it
curl http://192.168.1.10:<NodePort>
```

### Install MetalLB Load Balancer

```bash
# Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml

# Wait for pods to be ready
kubectl wait --namespace metallb-system \
  --for=condition=ready pod \
  --selector=app=metallb \
  --timeout=90s

# Configure IP pool
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.100-192.168.1.150
EOF
```

## 🐛 Troubleshooting

### SSH Connection Issues

```bash
# Test SSH manually to each node
ssh your-username@192.168.1.10
ssh your-username@192.168.1.11
ssh your-username@192.168.1.12
```

**Solution:** Ensure password authentication or SSH keys are configured on all nodes.

### K3s Not Starting

SSH into the master and check logs:

```bash
ssh your-username@192.168.1.10
sudo systemctl status k3s
sudo journalctl -u k3s -f
```

### Workers Not Joining

SSH into worker and check:

```bash
ssh your-username@192.168.1.11
sudo systemctl status k3s-agent
sudo journalctl -u k3s-agent -f
```

### Terraform Apply Fails

```bash
# Clean up and retry
terraform destroy
terraform apply
```

### Nodes Not Ready

```bash
# Check node status
kubectl describe node <node-name>

# Check for common issues:
# - Network connectivity
# - Firewall rules blocking ports 6443, 10250
# - Insufficient resources
```

## 📚 Learn More

### Documentation

- 📖 [USAGE.md](USAGE.md) - Detailed usage guide
- 🔒 [SECURITY.md](SECURITY.md) - Security best practices
- 🚀 [QUICK_START.md](QUICK_START.md) - Quick deployment reference

### Kubernetes Resources

- [K3s Documentation](https://docs.k3s.io/)
- [Kubernetes Basics](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)

### Advanced Topics

- [Proxmox Deployment](PROXMOX_DEPLOYMENT.md) - Full Proxmox automation
- [Deployment Comparison](DEPLOYMENT_COMPARISON.md) - Choose your deployment method

## 🔐 Security Notes

### Never Commit These Files

The `.gitignore` is configured to protect:

- ❌ `terraform.tfvars` - Contains passwords and IPs
- ❌ `kubeconfig.yaml` - Contains cluster access credentials
- ❌ `k3s-token.txt` - Contains cluster join token
- ❌ `*.tfstate*` - Contains sensitive state data
- ❌ `.terraform/` - Provider plugins directory

### Safe to Commit

- ✅ `*.tf` files - With placeholder values
- ✅ `terraform.tfvars.example` - Template file only
- ✅ Documentation (`*.md`)
- ✅ `.gitignore` - Protection configuration

See [SECURITY.md](SECURITY.md) for detailed security guidelines.

## 🔄 Cluster Management

### Update K3s Version

Edit `terraform.tfvars`:

```hcl
k3s_version = "v1.29.0+k3s1"
```

Then apply:

```bash
terraform apply
```

### Scale Workers

To add more workers, update `terraform.tfvars`:

```hcl
worker_ips = [
  "192.168.1.11",
  "192.168.1.12",
  "192.168.1.13"  # New worker
]
```

Apply changes:

```bash
terraform apply
```

### Destroy Cluster

```bash
# Remove entire cluster
terraform destroy
```

## 🎓 Learning Objectives

This homelab helps you learn:

- ✅ Kubernetes fundamentals and architecture
- ✅ Infrastructure as Code with Terraform
- ✅ Container orchestration
- ✅ DevOps practices and automation
- ✅ Linux system administration
- ✅ Networking and service discovery

## 📊 Resource Requirements

### Minimum per Node

- **CPU:** 2 cores
- **RAM:** 2GB
- **Disk:** 20GB
- **Network:** 1Gbps recommended

### Recommended for Production-like Setup

- **CPU:** 4 cores
- **RAM:** 4GB
- **Disk:** 40GB
- **Network:** 1Gbps+

## 🤝 Contributing

Found an issue or have an improvement? Feel free to:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [K3s](https://k3s.io/) - Lightweight Kubernetes distribution
- [Terraform](https://www.terraform.io/) - Infrastructure as Code tool
- [Proxmox VE](https://www.proxmox.com/) - Virtualization platform

## 📞 Support

- 📖 Check [USAGE.md](USAGE.md) for usage instructions
- 🐛 Check troubleshooting section above
- 🔒 Review [SECURITY.md](SECURITY.md) for security guidance

---

**Built for learning and experimentation.** Perfect for homelabs, development environments, and practicing Kubernetes administration.

⭐ **Star this repo if you find it helpful!**
