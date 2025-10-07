output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = local.argocd_namespace_name
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
  value       = "petclinic-${var.environment}"
}

output "application_namespace" {
  description = "Application target namespace"
  value       = var.app_namespace
}

output "argocd_server_nodeport" {
  description = "ArgoCD server NodePort"
  value       = var.argocd_node_port
}

output "argocd_https_nodeport" {
  description = "ArgoCD server HTTPS NodePort"
  value       = var.argocd_https_node_port
}
