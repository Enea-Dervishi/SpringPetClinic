variable "namespace" {
  description = "Kubernetes namespace for PetClinic application"
  type        = string
  default     = "petclinic"
}

variable "replicas" {
  description = "Number of replicas for the PetClinic deployment"
  type        = number
  default     = 1
}

variable "image_repository" {
  description = "Docker image repository for PetClinic"
  type        = string
  default     = "ghcr.io/enea-dervishi/petclinic"
}

variable "image_tag" {
  description = "Docker image tag for PetClinic"
  type        = string
  default     = "latest"
}

variable "container_port" {
  description = "Container port for PetClinic"
  type        = number
  default     = 8081
}

variable "service_port" {
  description = "Service port for PetClinic"
  type        = number
  default     = 8081
}

variable "node_port" {
  description = "Node port for PetClinic service"
  type        = number
  default     = 30081
}

variable "cpu_limit" {
  description = "CPU limit for PetClinic container"
  type        = string
  default     = "500m"
}

variable "memory_limit" {
  description = "Memory limit for PetClinic container"
  type        = string
  default     = "512Mi"
}

variable "cpu_request" {
  description = "CPU request for PetClinic container"
  type        = string
  default     = "200m"
}

variable "memory_request" {
  description = "Memory request for PetClinic container"
  type        = string
  default     = "256Mi"
}

variable "ghcr_username" {
  description = "GitHub username for Container Registry"
  type        = string
  sensitive   = true
}

variable "ghcr_token" {
  description = "GitHub Personal Access Token for Container Registry"
  type        = string
  sensitive   = true
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "petclinic"
}

variable "k8s_config_path" {
  description = "Path to the kubeconfig file"
  type        = string
  default     = "~/.kube/config"
}

variable "k8s_context" {
  description = "Kubernetes context to use"
  type        = string
  default     = "default"
}
