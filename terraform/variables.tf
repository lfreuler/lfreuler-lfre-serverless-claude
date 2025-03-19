# Variables for the main module

variable "app_name" {
  description = "The name of the application"
  type        = string
  default     = "dataservice"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "Environment must be one of: dev, test, prod."
  }
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "managed_by" {
  description = "How the resources are managed"
  type        = string
  default     = "Terraform"
}

variable "app_version" {
  description = "Version identifier for resources"
  type        = string
  default     = "v1"
}
