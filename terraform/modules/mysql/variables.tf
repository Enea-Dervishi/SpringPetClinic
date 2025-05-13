variable "namespace" {
  description = "Kubernetes namespace"
  type        = string
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "mysql_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
}

variable "mysql_user" {
  description = "MySQL user"
  type        = string
  default     = "petclinic"
}

variable "mysql_database" {
  description = "MySQL database name"
  type        = string
  default     = "petclinic"
} 