terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.4.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.k8s_config_path
  config_context = var.k8s_context != "" ? var.k8s_context : null
}

provider "kubectl" {
  config_path    = var.k8s_config_path
  config_context = var.k8s_context != "" ? var.k8s_context : null
} 