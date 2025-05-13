output "namespace_name" {
  description = "The name of the created namespace"
  value       = kubernetes_namespace.petclinic.metadata[0].name
}

output "service_nodeport" {
  description = "The NodePort of the service"
  value       = kubernetes_service.petclinic.spec[0].port[0].node_port
}

output "deployment_name" {
  description = "The name of the deployment"
  value       = kubernetes_deployment.petclinic.metadata[0].name
}

output "replicas" {
  description = "Number of replicas in the deployment"
  value       = kubernetes_deployment.petclinic.spec[0].replicas
}

output "access_url" {
  description = "URL to access the application (replace localhost with your node IP if needed)"
  value       = "http://localhost:${kubernetes_service.petclinic.spec[0].port[0].node_port}"
}
