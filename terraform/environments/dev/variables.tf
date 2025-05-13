variable "ghcr_username" {
  description = "GitHub username for Container Registry"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Personal Access Token for Container Registry"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
  default     = "not_used"  # Default value since MySQL is not used
}

variable "mysql_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
  default     = "not_used"  # Default value since MySQL is not used
}

variable "k8s_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "k3d-petclinic-cluster"
} 