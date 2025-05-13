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
