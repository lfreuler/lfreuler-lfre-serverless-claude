# API Gateway module - outputs.tf

output "api_endpoint" {
  description = "The API Gateway endpoint URL"
  value       = "${aws_api_gateway_deployment.deployment.invoke_url}"
}

output "api_key" {
  description = "The API Key for authenticating with the API"
  value       = aws_api_gateway_api_key.api_key.value
  sensitive   = true
}
