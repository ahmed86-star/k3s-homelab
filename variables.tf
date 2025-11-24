# Variables for K3s Cluster Deployment

variable "ssh_user" {
  description = "SSH username for all nodes"
  type        = string
  default     = "your-username"
}

variable "ssh_password" {
  description = "SSH password for authentication"
  type        = string
  sensitive   = true
}

variable "master_ip" {
  description = "IP address of the K3s master node"
  type        = string
  default     = "192.168.1.10"
}

variable "worker_ips" {
  description = "List of worker node IP addresses"
  type        = list(string)
  default     = ["192.168.1.11", "192.168.1.12"]
}

variable "k3s_version" {
  description = "K3s version to install"
  type        = string
  default     = "v1.28.5+k3s1"
}

variable "k3s_token" {
  description = "K3s cluster token (will be generated if not provided)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ssh_public_key" {
  description = "SSH public key for cloud-init (optional, uses password if not provided)"
  type        = string
  default     = ""
}

