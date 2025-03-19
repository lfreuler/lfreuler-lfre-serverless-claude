# API Gateway module - main.tf

# Create the API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "lfre-api-${var.app_name}-${var.environment}-${var.resource_version}"
  description = "API Gateway for ${var.app_name} ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Create resource for /items
resource "aws_api_gateway_resource" "items" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "items"
}

# Create resource for /items/{id}
resource "aws_api_gateway_resource" "item" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.items.id
  path_part   = "{id}"
}

# Create a GET method for /items
resource "aws_api_gateway_method" "get_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "GET"
  authorization = "NONE"
  api_key_required = true
}

# Integrate the GET /items method with the read Lambda function
resource "aws_api_gateway_integration" "get_items_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.get_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_read_invoke_arn
}

# Create a POST method for /items
resource "aws_api_gateway_method" "post_items" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.items.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

# Integrate the POST /items method with the write Lambda function
resource "aws_api_gateway_integration" "post_items_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.items.id
  http_method             = aws_api_gateway_method.post_items.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_write_invoke_arn
}

# Create a PUT method for /items/{id}
resource "aws_api_gateway_method" "put_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "PUT"
  authorization = "NONE"
  api_key_required = true
}

# Integrate the PUT /items/{id} method with the write Lambda function
resource "aws_api_gateway_integration" "put_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item.id
  http_method             = aws_api_gateway_method.put_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_write_invoke_arn
}

# Create a DELETE method for /items/{id}
resource "aws_api_gateway_method" "delete_item" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.item.id
  http_method   = "DELETE"
  authorization = "NONE"
  api_key_required = true
}

# Integrate the DELETE /items/{id} method with the write Lambda function
resource "aws_api_gateway_integration" "delete_item_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.item.id
  http_method             = aws_api_gateway_method.delete_item.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = var.lambda_write_invoke_arn
}

# Create deployment
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.get_items_integration,
    aws_api_gateway_integration.post_items_integration,
    aws_api_gateway_integration.put_item_integration,
    aws_api_gateway_integration.delete_item_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }
}

# Create stage (separated from deployment to avoid deprecation warning)
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

# Create API key
resource "aws_api_gateway_api_key" "api_key" {
  name = "lfre-apikey-${var.app_name}-${var.environment}-${var.resource_version}"
}

# Create usage plan
resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "lfre-usageplan-${var.app_name}-${var.environment}-${var.resource_version}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }

  quota_settings {
    limit  = 1000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 20
    rate_limit  = 10
  }
}

# Associate API key with usage plan
resource "aws_api_gateway_usage_plan_key" "usage_plan_key" {
  key_id        = aws_api_gateway_api_key.api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

# Grant API Gateway permission to invoke the Lambda functions
resource "aws_lambda_permission" "read_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_read_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any method on the API gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "write_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_write_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any method on the API gateway
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}
