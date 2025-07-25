variable "ghcr_username" {
  description = "GitHub Container Registry username"
  type        = string
}

variable "ghcr_token" {
  description = "GitHub Container Registry token"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
  default     = "not_used"  # Default value since MySQL is not used
}

variable "mysql_password" {
  description = "MySQL user password"
  type        = string
  sensitive   = true
  default     = "not_used"  # Default value since MySQL is not used
}

variable "build_number" {
  description = "Build number for image tagging"
  type        = string
  default     = ""
} 
