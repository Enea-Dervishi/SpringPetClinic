# ArgoCD Installation and Configuration Module

terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
  }
}

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
    prevent_destroy = true
  }
}

# Local value to reference the namespace regardless of how it was obtained
locals {
  argocd_namespace_name = try(data.kubernetes_namespace.argocd_existing.metadata[0].name, kubernetes_namespace.argocd[0].metadata[0].name)
}

# Install ArgoCD using the official manifests
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

# Apply ArgoCD manifests directly without splitting
resource "kubectl_manifest" "argocd_install" {
  yaml_body = data.http.argocd_install.response_body
  override_namespace = "argocd"
  depends_on = [data.kubernetes_namespace.argocd_existing, kubernetes_namespace.argocd]
}

# Wait for ArgoCD server to be ready
resource "null_resource" "wait_for_argocd" {
  depends_on = [kubectl_manifest.argocd_install]
  
  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=600s"
  }
}

resource "kubectl_manifest" "petclinic_application" {
  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = "petclinic-${var.environment}"
      namespace = "argocd"
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
  
  depends_on = [null_resource.wait_for_argocd]
}

resource "kubernetes_service" "argocd_server_nodeport" {
  metadata {
    name      = "argocd-server-nodeport"
    namespace = "argocd"
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
