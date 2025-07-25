variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "git_repo_url" {
  description = "Git repository URL containing Kubernetes manifests"
  type        = string
}

variable "git_branch" {
  description = "Git branch to track"
  type        = string
  default     = "main"
}

variable "app_namespace" {
  description = "Kubernetes namespace for the application"
  type        = string
}

variable "argocd_node_port" {
  description = "NodePort for ArgoCD HTTP service"
  type        = number
  default     = 30080
}

variable "argocd_https_node_port" {
  description = "NodePort for ArgoCD HTTPS service"
  type        = number
  default     = 30443
}

variable "kubernetes_host" {
  description = "Kubernetes API server endpoint"
  type        = string
}

variable "kubernetes_token" {
  description = "Kubernetes service account token"
  type        = string
  sensitive   = true
}

variable "kubernetes_ca_certificate" {
  description = "Kubernetes cluster CA certificate (base64 encoded)"
  type        = string
}
