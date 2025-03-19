# Lambda module - outputs.tf

output "read_function_name" {
  description = "The name of the read Lambda function"
  value       = aws_lambda_function.read_function.function_name
}

output "read_function_arn" {
  description = "The ARN of the read Lambda function"
  value       = aws_lambda_function.read_function.arn
}

output "read_function_invoke_arn" {
  description = "The invoke ARN of the read Lambda function"
  value       = aws_lambda_function.read_function.invoke_arn
}

output "write_function_name" {
  description = "The name of the write Lambda function"
  value       = aws_lambda_function.write_function.function_name
}

output "write_function_arn" {
  description = "The ARN of the write Lambda function"
  value       = aws_lambda_function.write_function.arn
}

output "write_function_invoke_arn" {
  description = "The invoke ARN of the write Lambda function"
  value       = aws_lambda_function.write_function.invoke_arn
}
