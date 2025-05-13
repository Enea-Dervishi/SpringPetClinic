terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

provider "kubernetes" {
  config_path = "/etc/rancher/k3s/k3s.yaml"
}

# Use environment-specific variables
locals {
  env_vars = { for k, v in var.environments[var.tf_env] : k => v }
  database_enabled = local.env_vars.database_enabled != null ? tobool(local.env_vars.database_enabled) : false
}

# Only create kubernetes module for now
module "kubernetes" {
  source = "./terraform/modules/kubernetes"
  
  environment        = var.tf_env
  namespace          = local.env_vars.namespace != null ? local.env_vars.namespace : var.namespace
  replicas           = local.env_vars.replicas != null ? tonumber(local.env_vars.replicas) : var.replicas
  container_image    = local.env_vars.container_image != null ? local.env_vars.container_image : var.container_image
  app_name           = "petclinic"
  container_port     = 8081
  service_port       = 80
  service_type       = local.env_vars.service_type != null ? local.env_vars.service_type : "NodePort"
  
  # Skip database for now
  database_enabled   = false
  db_name            = ""
  db_username        = ""
  db_password        = ""
  db_host            = ""
}
