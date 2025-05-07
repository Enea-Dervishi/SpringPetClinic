terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

# Create a namespace for the pet clinic
resource "kubernetes_namespace" "petclinic" {
  metadata {
    name = "petclinic"
  }
}

# Create a deployment for the Spring PetClinic application
resource "kubernetes_deployment" "petclinic" {
  metadata {
    name      = "petclinic"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  spec {
    replicas = 1

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
        image_pull_secrets{
          name = "ghcr-secret"
        }
        
        container {
          image = "ghcr.io/enea-dervishi/spring-petclinic:latest"
          name  = "petclinic"

          port {
            container_port = 8081
          }

          env {
            name  = "SERVER_PORT"
            value = "8081"
          }
        }
      }
    }
  }
}

# Create a service to expose the application
resource "kubernetes_service" "petclinic" {
  metadata {
    name      = "petclinic"
    namespace = kubernetes_namespace.petclinic.metadata[0].name
  }

  spec {
    selector = {
      app = "petclinic"
    }

    port {
      port        = 80
      target_port = 8081
    }

    type = "NodePort"
  }
} 
