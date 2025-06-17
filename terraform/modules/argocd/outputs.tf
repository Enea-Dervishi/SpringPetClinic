output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service" {
  description = "ArgoCD server service name"
  value       = kubernetes_service.argocd_server_nodeport.metadata[0].name
}

output "argocd_ui_url" {
  description = "ArgoCD UI URL"
  value       = "http://localhost:${var.argocd_node_port}"
}

output "application_name" {
  description = "ArgoCD Application name"
  value       = kubernetes_manifest.petclinic_application.manifest.metadata.name
} 