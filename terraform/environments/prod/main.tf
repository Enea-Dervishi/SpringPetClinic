module "petclinic" {
  source = "../../modules/kubernetes"

  namespace        = "petclinic-prod"
  replicas         = 3
  image_repository = "springcommunity/spring-petclinic"
  image_tag        = "latest"  # In production, you should use specific version tags
  container_port   = 8081
  service_port     = 8081
  node_port        = 30083
  
  # Resource limits for production environment
  cpu_limit      = "2000m"
  memory_limit   = "2Gi"
  cpu_request    = "1000m"
  memory_request = "1Gi"
}
