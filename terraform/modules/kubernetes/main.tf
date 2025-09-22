resource "kubernetes_namespace" "app_namespace" {
  metadata {
    name = var.namespace
    labels = {
      app = "petclinic"
      environment = replace(var.namespace, "petclinic-", "")
    }
  }
}

resource "kubernetes_deployment" "petclinic" {
  depends_on = [kubernetes_namespace.app_namespace]
  
  metadata {
    name      = "petclinic"
    namespace = var.namespace
    labels = {
      app = "petclinic"
    }
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
        container {
          name  = "petclinic"
          image = "${var.image_repository}:${var.image_tag}"
          
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
            name  = "SPRING_PROFILES_ACTIVE"
            value = "k8s"
          }
          
          env {
            name  = "SERVER_PORT"
            value = tostring(var.container_port)
          }

          liveness_probe {
            http_get {
              path = "/manage/health"
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/manage/health"
              port = var.container_port
            }
            initial_delay_seconds = 20
            period_seconds        = 5
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "petclinic" {
  depends_on = [kubernetes_deployment.petclinic]
  
  metadata {
    name      = "petclinic-service"
    namespace = var.namespace
    labels = {
      app = "petclinic"
    }
  }

  spec {
    selector = {
      app = "petclinic"
    }

    port {
      name        = "http"
      port        = var.service_port
      target_port = var.container_port
      node_port   = var.node_port
    }

    type = "NodePort"
  }
}