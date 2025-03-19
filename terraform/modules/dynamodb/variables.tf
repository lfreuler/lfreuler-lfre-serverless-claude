# DynamoDB module - variables.tf

variable "app_name" {
  description = "The name of the application"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "owner" {
  description = "Owner of the resources"
  type        = string
}

variable "managed_by" {
  description = "How the resources are managed"
  type        = string
}

variable "version" {
  description = "Version identifier for resources"
  type        = string
}
