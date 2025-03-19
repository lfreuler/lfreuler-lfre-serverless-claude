# Main Terraform configuration file

module "dynamodb" {
  source = "./modules/dynamodb"

  app_name    = var.app_name
  environment = var.environment
  owner       = var.owner
  managed_by  = var.managed_by
  version     = var.version
}

module "lambda" {
  source = "./modules/lambda"

  app_name    = var.app_name
  environment = var.environment
  owner       = var.owner
  managed_by  = var.managed_by
  version     = var.version

  dynamodb_table_name  = module.dynamodb.table_name
  dynamodb_table_arn   = module.dynamodb.table_arn
}

module "api_gateway" {
  source = "./modules/api_gateway"

  app_name    = var.app_name
  environment = var.environment
  owner       = var.owner
  managed_by  = var.managed_by
  version     = var.version

  lambda_read_name  = module.lambda.read_function_name
  lambda_read_arn   = module.lambda.read_function_arn
  lambda_read_invoke_arn = module.lambda.read_function_invoke_arn
  
  lambda_write_name = module.lambda.write_function_name
  lambda_write_arn  = module.lambda.write_function_arn
  lambda_write_invoke_arn = module.lambda.write_function_invoke_arn
}
