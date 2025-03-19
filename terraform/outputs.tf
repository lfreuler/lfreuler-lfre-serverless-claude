# Output variables

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = module.api_gateway.api_endpoint
}

output "api_key" {
  description = "The API Key for authenticating with the API"
  value       = module.api_gateway.api_key
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  value       = module.dynamodb.table_name
}
