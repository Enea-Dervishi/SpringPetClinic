variable "namespace" {
  description = "Kubernetes namespace to deploy to"
  type        = string
}

variable "replicas" {
  description = "Number of replicas for the deployment"
  type        = number
  default     = 1
}

variable "image_repository" {
  description = "Docker image repository"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Port that the container listens on"
  type        = number
  default     = 8085
}

variable "service_port" {
  description = "Port that the service exposes"
  type        = number
  default     = 8085
}

variable "node_port" {
  description = "NodePort for external access"
  type        = number
  default     = 30082
}

variable "cpu_limit" {
  description = "CPU limit for the container"
  type        = string
  default     = "1000m"
}

variable "memory_limit" {
  description = "Memory limit for the container"
  type        = string
  default     = "1Gi"
}

variable "cpu_request" {
  description = "CPU request for the container"
  type        = string
  default     = "500m"
}

variable "memory_request" {
  description = "Memory request for the container"
  type        = string
  default     = "512Mi"
}