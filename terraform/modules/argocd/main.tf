# ArgoCD Installation and Configuration Module

# Install ArgoCD using the official manifests
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

# Split the multi-document YAML
locals {
  argocd_manifests_raw = split("---", data.http.argocd_install.response_body)
  
  # Filter and categorize manifests
  argocd_manifests_filtered = [
    for doc in local.argocd_manifests_raw : 
    doc if length(regexall("(?m)^(apiVersion|kind):", doc)) > 0
  ]
  
  # Separate namespace from other resources
  namespace_manifest = [
    for doc in local.argocd_manifests_filtered :
    doc if length(regexall("(?m)^kind:\\s*Namespace", doc)) > 0
  ]
  
  other_manifests = [
    for doc in local.argocd_manifests_filtered :
    doc if length(regexall("(?m)^kind:\\s*Namespace", doc)) == 0
  ]
}

# Create namespace first
resource "kubectl_manifest" "argocd_namespace" {
  count = length(local.namespace_manifest) > 0 ? 1 : 0
  
  yaml_body = local.namespace_manifest[0]
  wait      = true
}

# Then create all other resources
resource "kubectl_manifest" "argocd_install" {
  for_each = { for idx, doc in local.other_manifests : idx => doc }
  
  yaml_body          = each.value
  override_namespace = "argocd"
  wait               = true
  
  depends_on = [kubectl_manifest.argocd_namespace]
}

# Local value for namespace name
locals {
  argocd_namespace_name = "argocd"
}

# Wait for ArgoCD to fully initialize
resource "time_sleep" "wait_for_argocd" {
  depends_on = [kubectl_manifest.argocd_install]
  
  create_duration = "60s"
}

# Create ArgoCD Application for PetClinic
resource "kubectl_manifest" "petclinic_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "petclinic-${var.environment}"
      namespace = local.argocd_namespace_name
    }
    spec = {
      project = "default"
      source = {
        repoURL        = var.git_repo_url
        targetRevision = var.git_branch
        path           = "k8s/overlays/${var.environment}"
      }
      destination = {
        server    = "https://kubernetes.default.svc"
        namespace = var.app_namespace
      }
      syncPolicy = {
        automated = {
          prune    = true
          selfHeal = true
        }
        syncOptions = [
          "CreateNamespace=true"
        ]
      }
    }
  })
  
  depends_on = [time_sleep.wait_for_argocd]
}

# Create NodePort service to access ArgoCD UI
resource "kubernetes_service" "argocd_server_nodeport" {
  metadata {
    name      = "argocd-server-nodeport"
    namespace = local.argocd_namespace_name
  }

  spec {
    type = "NodePort"
    
    port {
      port        = 80
      target_port = 8080
      node_port   = var.argocd_node_port
      protocol    = "TCP"
      name        = "http"
    }
    
    port {
      port        = 443
      target_port = 8080
      node_port   = var.argocd_https_node_port
      protocol    = "TCP"
      name        = "https"
    }

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
  }
  
  depends_on = [kubectl_manifest.argocd_install]
}
