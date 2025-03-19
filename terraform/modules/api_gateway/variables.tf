# API Gateway module - variables.tf

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

variable "lambda_read_name" {
  description = "The name of the read Lambda function"
  type        = string
}

variable "lambda_read_arn" {
  description = "The ARN of the read Lambda function"
  type        = string
}

variable "lambda_read_invoke_arn" {
  description = "The invoke ARN of the read Lambda function"
  type        = string
}

variable "lambda_write_name" {
  description = "The name of the write Lambda function"
  type        = string
}

variable "lambda_write_arn" {
  description = "The ARN of the write Lambda function"
  type        = string
}

variable "lambda_write_invoke_arn" {
  description = "The invoke ARN of the write Lambda function"
  type        = string
}
