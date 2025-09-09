# ArgoCD Installation and Configuration Module

# Create ArgoCD namespace
resource "kubernetes_namespace" "argocd" {
  metadata {
    name = "argocd"
  }
}

# Install ArgoCD using the official manifests
data "http" "argocd_install" {
  url = "https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml"
}

resource "kubectl_manifest" "argocd_install" {
  for_each = {
    for manifest in split("---", data.http.argocd_install.response_body) :
      "${sha1(manifest)}" => manifest
    #if length(regexall("(?m)^(kind|apiVersion):", manifest)) > 1
  }
  
  yaml_body          = each.value
  override_namespace = "argocd"
  depends_on = [kubernetes_namespace.argocd]
}

resource "time_sleep" "wait_for_argocd" {
  depends_on = [kubectl_manifest.argocd_install]
  create_duration = "300s"
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
  
  depends_on = [time_sleep.wait_for_argocd]
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
