resource "kubernetes_persistent_volume_claim" "mysql_pvc" {
  metadata {
    name      = "mysql-pvc"
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

resource "kubernetes_secret" "mysql_secret" {
  metadata {
    name      = "mysql-secret"
    namespace = var.namespace
  }

  data = {
    "mysql-root-password" = var.mysql_root_password
    "mysql-password"      = var.mysql_password
    "mysql-database"      = var.mysql_database
    "mysql-user"         = var.mysql_user
  }
}

resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0"

          port {
            container_port = 3306
          }

          env {
            name = "MYSQL_ROOT_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-root-password"
              }
            }
          }

          env {
            name = "MYSQL_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-password"
              }
            }
          }

          env {
            name = "MYSQL_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-user"
              }
            }
          }

          env {
            name = "MYSQL_DATABASE"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.mysql_secret.metadata[0].name
                key  = "mysql-database"
              }
            }
          }

          volume_mount {
            name       = "mysql-storage"
            mount_path = "/var/lib/mysql"
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            tcp_socket {
              port = 3306
            }
            initial_delay_seconds = 30
            period_seconds       = 10
          }

          readiness_probe {
            tcp_socket {
              port = 3306
            }
            initial_delay_seconds = 5
            period_seconds       = 10
          }
        }

        volume {
          name = "mysql-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.mysql_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = var.namespace
  }

  spec {
    selector = {
      app = kubernetes_deployment.mysql.spec[0].template[0].metadata[0].labels.app
    }

    port {
      port        = 3306
      target_port = 3306
    }

    type = "ClusterIP"
  }
} 