variable "app_name" {
  description = "Application name"
  type        = string
  default     = "petclinic"
}

variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "replicas" {
  description = "Number of replicas"
  type        = number
  default     = 1
}

variable "image_repository" {
  description = "Container image repository"
  type        = string
}

variable "image_tag" {
  description = "Container image tag"
  type        = string
}

variable "container_port" {
  description = "Container port"
  type        = number
  default     = 8081
}

variable "service_port" {
  description = "Service port"
  type        = number
  default     = 8081
}

variable "node_port" {
  description = "NodePort"
  type        = number
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request"
  type        = string
  default     = "200m"
}

variable "memory_request" {
  description = "Memory request"
  type        = string
  default     = "256Mi"
}

variable "ghcr_username" {
  description = "GitHub Container Registry username"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Container Registry token"
  type        = string
  sensitive   = true
}

variable "ghcr_secret_name" {
  description = "Name of the GHCR secret"
  type        = string
  default     = "ghcr-secret"
}

variable "output_path" {
  description = "Path where to generate the manifests"
  type        = string
} 