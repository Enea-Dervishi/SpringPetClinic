output "namespace" {
  description = "The namespace where resources are deployed"
  value       = kubernetes_namespace.app_namespace.metadata[0].name
}

output "deployment_name" {
  description = "Name of the Kubernetes deployment"
  value       = kubernetes_deployment.petclinic.metadata[0].name
}

output "service_name" {
  description = "Name of the Kubernetes service"
  value       = kubernetes_service.petclinic.metadata[0].name
}

output "service_port" {
  description = "Port of the Kubernetes service"
  value       = kubernetes_service.petclinic.spec[0].port[0].port
}

output "node_port" {
  description = "NodePort of the Kubernetes service"
  value       = kubernetes_service.petclinic.spec[0].port[0].node_port
}