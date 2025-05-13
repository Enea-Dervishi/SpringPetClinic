variable "ghcr_username" {
  description = "GitHub username for Container Registry"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Personal Access Token for Container Registry"
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