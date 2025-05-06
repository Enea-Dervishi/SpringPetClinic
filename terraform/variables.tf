variable "tf_env" {
  description = "Environment name (dev/staging/prod)"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the PetClinic application"
  type        = string
  default     = "petclinic"
}

variable "replicas" {
  description = "Number of replicas for the PetClinic deployment"
  type        = number
  default     = 1
}

variable "container_image" {
  description = "Container image for the PetClinic application"
  type        = string
  default     = "springcommunity/spring-petclinic:latest"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "db_instance_type" {
  description = "RDS instance type"
  type        = string
  default     = "db.t2.micro"
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "petclinic"
}

variable "db_username" {
  description = "Database username"
  type        = string
  default     = "petclinic"
}

variable "db_password" {
  description = "Database password"
  type        = string
  default     = "petclinic"
} 