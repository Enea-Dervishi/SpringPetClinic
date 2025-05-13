# Kubernetes module to manage all K8s resources

resource "kubernetes_namespace" "petclinic" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "ghcr_secret" {
  metadata {
    name      = "ghcr-secret"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "ghcr.io" = {
          auth = base64encode("${var.ghcr_username}:${var.ghcr_token}")
        }
      }
    })
  }
}

resource "kubernetes_deployment" "petclinic" {
  metadata {
    name      = "petclinic"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "petclinic"
      }
    }

    template {
      metadata {
        labels = {
          app = "petclinic"
        }
      }

      spec {
        image_pull_secrets {
          name = kubernetes_secret.ghcr_secret.metadata[0].name
        }

        container {
          image = "${var.image_repository}:${var.image_tag}"
          name  = "petclinic"

          port {
            container_port = var.container_port
          }

          resources {
            limits = {
              cpu    = var.cpu_limit
              memory = var.memory_limit
            }
            requests = {
              cpu    = var.cpu_request
              memory = var.memory_request
            }
          }

          env {
            name  = "SERVER_PORT"
            value = tostring(var.container_port)
          }

          # Add liveness probe
          liveness_probe {
            http_get {
              path = "/manage/health"
              port = var.container_port
            }
            initial_delay_seconds = 120
            period_seconds       = 15
          }

          # Add readiness probe
          readiness_probe {
            http_get {
              path = "/manage/health"
              port = var.container_port
            }
            initial_delay_seconds = 60
            period_seconds       = 10
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "petclinic" {
  metadata {
    name      = "petclinic"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  spec {
    selector = {
      app = kubernetes_deployment.petclinic.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = var.service_port
      target_port = var.container_port
      node_port   = var.node_port
    }

    type = "NodePort"
  }
}
