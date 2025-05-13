module "petclinic" {
  source = "../../modules/kubernetes"

  namespace        = "petclinic-dev"
  replicas         = 1
  image_repository = "ghcr.io/enea-dervishi/petclinic"
  image_tag        = "latest"
  container_port   = 8081
  service_port     = 8081
  node_port        = 30081
  
  # Resource limits for dev environment
  cpu_limit      = "500m"
  memory_limit   = "512Mi"
  cpu_request    = "200m"
  memory_request = "256Mi"

  # GitHub Container Registry credentials
  ghcr_username = var.ghcr_username
  ghcr_token    = var.ghcr_token
}
