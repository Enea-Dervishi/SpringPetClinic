# ArgoCD Installation and Configuration Module

# Try to get existing ArgoCD namespace
data "kubernetes_namespace" "argocd_existing" {
  metadata {
    name = "argocd"
  }
}

# Create ArgoCD namespace only if it doesn't exist
resource "kubernetes_namespace" "argocd" {
  count = try(data.kubernetes_namespace.argocd_existing.metadata[0].name, null) == null ? 1 : 0
  
  metadata {
    name = "argocd"
  }
  
  lifecycle {
    ignore_changes = [metadata[0].annotations, metadata[0].labels]
  }
}

# Local value to reference the namespace regardless of how it was obtained
locals {
  argocd_namespace_name = try(
    data.kubernetes_namespace.argocd_existing.metadata[0].name,
    kubernetes_namespace.argocd[0].metadata[0].name,
    "argocd"
  )
}

# Install ArgoCD using the official manifests
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

# Apply ArgoCD manifests
resource "kubectl_manifest" "argocd_install" {
  yaml_body          = data.http.argocd_install.response_body
  override_namespace = local.argocd_namespace_name
  wait               = true
  wait_for_rollout   = true
  
  depends_on = [kubernetes_namespace.argocd]
}

# Wait for ArgoCD to fully initialize
resource "time_sleep" "wait_for_argocd" {
  depends_on = [kubectl_manifest.argocd_install]
  
  create_duration = "30s"
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
