# ArgoCD outputs commented out since module is disabled
# output "argocd_namespace" {
#   description = "The ArgoCD namespace"
#   value       = module.argocd.argocd_namespace
# }

# output "argocd_ui_url" {
#   description = "ArgoCD UI URL"
#   value       = module.argocd.argocd_ui_url
# }

# output "application_name" {
#   description = "ArgoCD Application name"
#   value       = module.argocd.application_name
# }

output "manifests_generated" {
  description = "Path where manifests were generated"
  value       = "k8s-manifests/environments/dev"
}
