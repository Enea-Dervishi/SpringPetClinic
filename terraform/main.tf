terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
  }
}

provider "kubernetes" {
  host                   = var.kubernetes_host
  token                  = var.kubernetes_token
  cluster_ca_certificate = base64decode(var.kubernetes_ca_certificate)
  insecure               = true
}

# Use environment-specific variables
locals {
  env_vars = { for k, v in var.environments[var.tf_env] : k => v }
  database_enabled = local.env_vars.database_enabled != null ? tobool(local.env_vars.database_enabled) : false
}
