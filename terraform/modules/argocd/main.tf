# ArgoCD Installation and Configuration Module

# Create ArgoCD namespace explicitly
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
  
  lifecycle {
    ignore_changes = [metadata[0].annotations, metadata[0].labels]
  }
}

# Local value for namespace name
locals {
  argocd_namespace_name = kubernetes_namespace.argocd.metadata[0].name
}

# Install ArgoCD using the official manifests
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

# Split the multi-document YAML
locals {
  argocd_manifests = [
    for doc in split("---", data.http.argocd_install.response_body) : 
    trimspace(doc) if length(regexall("(?m)^(apiVersion|kind):", doc)) > 0 && length(regexall("(?m)^kind:\\s*Namespace", doc)) == 0
  ]
}

# Apply all ArgoCD manifests (excluding any Namespace definitions)
resource "kubectl_manifest" "argocd_install" {
  for_each = { for idx, doc in local.argocd_manifests : idx => doc }
  
  yaml_body          = each.value
  override_namespace = local.argocd_namespace_name
  wait               = false  # Don't wait for each individual resource
  
  depends_on = [kubernetes_namespace.argocd]
}

# Wait for ArgoCD server deployment to be ready
resource "kubernetes_manifest" "wait_for_argocd_server" {
  manifest = {
    apiVersion = "v1"
    kind       = "ConfigMap"
    metadata = {
      name      = "argocd-wait-marker"
      namespace = local.argocd_namespace_name
    }
    data = {
      status = "waiting"
    }
  }
  
  wait {
    condition {
      type   = "Ready"
      status = "True"
    }
  }
  
  depends_on = [kubectl_manifest.argocd_install]
  
  lifecycle {
    ignore_changes = all
  }
}

# Wait for ArgoCD to fully initialize
resource "time_sleep" "wait_for_argocd" {
  depends_on = [kubectl_manifest.argocd_install]
  
  create_duration = "90s"
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
