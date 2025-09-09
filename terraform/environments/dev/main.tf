# Install ArgoCD
module "argocd" {
  source = "../../modules/argocd"

  environment   = "dev"
  git_repo_url  = "https://github.com/enea-dervishi/SpringPetClinic.git"
  git_branch    = "main"
  app_namespace = "petclinic-dev"

  kubernetes_host            = var.kubernetes_host
  kubernetes_token           = var.kubernetes_token
  kubernetes_ca_certificate  = var.kubernetes_ca_certificate
  
  argocd_node_port       = 30080
  argocd_https_node_port = 30443
}

# Legacy direct deployment (can be removed once GitOps is working)
# module "petclinic" {
#   source = "../../modules/kubernetes"
#
#   namespace        = "petclinic-dev"
#   replicas         = 1
#   image_repository = "ghcr.io/enea-dervishi/petclinic"
#   image_tag        = "latest"
#   container_port   = 8081
#   service_port     = 8081
#   node_port        = 30081
#   
#   # Resource limits for dev environment
#   cpu_limit      = "500m"
#   memory_limit   = "512Mi"
#   cpu_request    = "200m"
#   memory_request = "256Mi"
#
#   # GitHub Container Registry credentials
#   ghcr_username = var.ghcr_username
#   ghcr_token    = var.ghcr_token
#
#   # Kubernetes configuration
#   k8s_config_path = var.k8s_config_path
#   k8s_context     = var.k8s_context
# }
