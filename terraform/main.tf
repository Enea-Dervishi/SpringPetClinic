terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-terraform-k8s-demo"
}

# Use environment-specific variables
locals {
  env_vars = { for k, v in var.environments[var.tf_env] : k => v }
  database_enabled = local.env_vars.database_enabled != null ? tobool(local.env_vars.database_enabled) : false
}
