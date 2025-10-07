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

# Apply ArgoCD manifests directly without splitting
resource "kubectl_manifest" "argocd_install" {
  yaml_body = data.http.argocd_install.response_body
  override_namespace = "argocd"
  depends_on = [kubernetes_namespace.argocd]
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
