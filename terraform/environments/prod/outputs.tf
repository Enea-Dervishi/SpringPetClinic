output "kubernetes_namespace" {
  description = "The Kubernetes namespace where PetClinic is deployed"
  value       = module.petclinic.kubernetes_namespace
}

output "service_endpoint" {
  description = "The endpoint URL for the PetClinic service"
  value       = module.petclinic.service_endpoint
}

output "deployment_status" {
  description = "Status of the PetClinic deployment"
  value       = module.petclinic.deployment_status
}

output "environment" {
  description = "The current deployment environment"
  value       = module.petclinic.environment
}

output "namespace" {
  description = "The namespace where the application is deployed"
  value       = module.petclinic.namespace_name
}

output "service_nodeport" {
  description = "The NodePort of the service"
  value       = module.petclinic.service_nodeport
}

output "deployment_name" {
  description = "The name of the deployment"
  value       = module.petclinic.deployment_name
}

output "replicas" {
  description = "Number of replicas in the deployment"
  value       = module.petclinic.replicas
}

output "access_url" {
  description = "URL to access the application"
  value       = module.petclinic.access_url
}
