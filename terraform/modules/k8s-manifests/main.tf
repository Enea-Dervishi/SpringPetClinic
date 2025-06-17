# Generate Kubernetes manifests for GitOps

# Create deployment manifest
resource "local_file" "deployment_manifest" {
  filename = "${var.output_path}/deployment.yaml"
  content = templatefile("${path.module}/templates/deployment.yaml.tpl", {
    app_name         = var.app_name
    namespace        = var.namespace
    replicas         = var.replicas
    image_repository = var.image_repository
    image_tag        = var.image_tag
    container_port   = var.container_port
    cpu_limit        = var.cpu_limit
    memory_limit     = var.memory_limit
    cpu_request      = var.cpu_request
    memory_request   = var.memory_request
    ghcr_secret_name = var.ghcr_secret_name
  })
}

# Create service manifest
resource "local_file" "service_manifest" {
  filename = "${var.output_path}/service.yaml"
  content = templatefile("${path.module}/templates/service.yaml.tpl", {
    app_name      = var.app_name
    namespace     = var.namespace
    service_port  = var.service_port
    container_port = var.container_port
    node_port     = var.node_port
  })
}

# Create namespace manifest
resource "local_file" "namespace_manifest" {
  filename = "${var.output_path}/namespace.yaml"
  content = templatefile("${path.module}/templates/namespace.yaml.tpl", {
    namespace = var.namespace
  })
}

# Create GHCR secret manifest
resource "local_file" "ghcr_secret_manifest" {
  filename = "${var.output_path}/ghcr-secret.yaml"
  content = templatefile("${path.module}/templates/ghcr-secret.yaml.tpl", {
    namespace        = var.namespace
    secret_name      = var.ghcr_secret_name
    ghcr_username    = var.ghcr_username
    ghcr_token       = var.ghcr_token
  })
}

# Create kustomization file
resource "local_file" "kustomization" {
  filename = "${var.output_path}/kustomization.yaml"
  content = templatefile("${path.module}/templates/kustomization.yaml.tpl", {
    app_name = var.app_name
  })
} 