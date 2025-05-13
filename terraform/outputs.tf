output "kubernetes_namespace" {
  description = "The Kubernetes namespace where PetClinic is deployed"
  value       = module.kubernetes.namespace_name
}

output "service_endpoint" {
  description = "The endpoint URL for the PetClinic service"
  value       = module.kubernetes.service_endpoint
}

output "deployment_status" {
  description = "Status of the PetClinic deployment"
  value       = module.kubernetes.deployment_status
}

output "environment" {
  description = "The current deployment environment"
  value       = var.tf_env
}
