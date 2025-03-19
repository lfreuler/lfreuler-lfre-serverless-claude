# DynamoDB module - main.tf

resource "aws_dynamodb_table" "table" {
  name         = "lfre-dynamo-${var.app_name}-${var.environment}-${var.resource_version}"
  billing_mode = "PAY_PER_REQUEST"  # On-demand capacity mode
  hash_key     = "id"
  range_key    = "timestamp"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = var.environment == "prod" ? true : false
  }
}
