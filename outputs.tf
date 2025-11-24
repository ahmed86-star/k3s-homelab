# Outputs for K3s Cluster

output "master_ip" {
  description = "IP address of the K3s master node"
  value       = var.master_ip
}

output "worker_ips" {
  description = "IP addresses of the worker nodes"
  value       = var.worker_ips
}

output "kubeconfig_path" {
  description = "Path to the kubeconfig file"
  value       = "${path.cwd}/kubeconfig.yaml"
}

output "k3s_token_path" {
  description = "Path to the K3s token file"
  value       = "${path.cwd}/k3s-token.txt"
}

output "cluster_endpoint" {
  description = "K3s cluster API endpoint"
  value       = "https://${var.master_ip}:6443"
}

output "next_steps" {
  description = "Next steps to use the cluster"
  value       = <<-EOT
    
    ========================================
    K3s Cluster Deployed Successfully!
    ========================================
    
    Master Node: ${var.master_ip}
    Worker Nodes: ${join(", ", var.worker_ips)}
    
    To use kubectl:
      $env:KUBECONFIG="$PWD\kubeconfig.yaml"
      kubectl get nodes
      kubectl get pods -A
    
    Kubeconfig saved to: kubeconfig.yaml
    Cluster token saved to: k3s-token.txt
  EOT
}



