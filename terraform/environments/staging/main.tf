module "petclinic" {
  source = "../../modules/kubernetes"

  namespace        = "petclinic-staging"
  replicas         = 2
  image_repository = "springcommunity/spring-petclinic"
  image_tag        = "latest"
  container_port   = 8081
  service_port     = 8081
  node_port        = 30082
  
  # Resource limits for staging environment
  cpu_limit      = "1000m"
  memory_limit   = "1Gi"
  cpu_request    = "500m"
  memory_request = "512Mi"
}
