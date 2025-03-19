# Lambda module - main.tf

# Create the IAM role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "lfre-role-lambda-${var.app_name}-${var.environment}-${var.resource_version}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Attach the AWSLambdaBasicExecutionRole policy for CloudWatch logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Create a policy for DynamoDB access
resource "aws_iam_policy" "dynamodb_access" {
  name        = "lfre-policy-dynamodb-${var.app_name}-${var.environment}-${var.resource_version}"
  description = "Policy for DynamoDB access from Lambda functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}

# Attach the DynamoDB policy to the Lambda role
resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# Create the read Lambda function
data "archive_file" "read_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/read_function.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  const AWS = require('aws-sdk');
  const documentClient = new AWS.DynamoDB.DocumentClient();
  const tableName = process.env.DYNAMODB_TABLE;

  try {
    // Handle different HTTP methods
    if (event.httpMethod === 'GET') {
      // If id is provided, get specific item
      if (event.queryStringParameters && event.queryStringParameters.id) {
        const id = event.queryStringParameters.id;

        // Query DynamoDB for items with the given ID, sorted by timestamp
        const params = {
          TableName: tableName,
          KeyConditionExpression: 'id = :id',
          ExpressionAttributeValues: {
            ':id': id
          },
          ScanIndexForward: false // Sort by timestamp in descending order
        };

        const result = await documentClient.query(params).promise();
        
        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(result.Items)
        };
      } 
      // Otherwise, scan for all items (with pagination support)
      else {
        const params = {
          TableName: tableName,
          Limit: 50
        };

        // Support pagination with LastEvaluatedKey
        if (event.queryStringParameters && event.queryStringParameters.nextToken) {
          params.ExclusiveStartKey = JSON.parse(decodeURIComponent(event.queryStringParameters.nextToken));
        }

        const result = await documentClient.scan(params).promise();
        
        // Prepare response with pagination token if available
        const response = {
          items: result.Items,
          count: result.Count
        };
        
        if (result.LastEvaluatedKey) {
          response.nextToken = encodeURIComponent(JSON.stringify(result.LastEvaluatedKey));
        }

        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(response)
        };
      }
    }

    // If not a GET request
    return {
      statusCode: 405,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};
EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "read_function" {
  function_name    = "lfre-lambda-read-${var.app_name}-${var.environment}-${var.resource_version}"
  filename         = data.archive_file.read_lambda_zip.output_path
  source_code_hash = data.archive_file.read_lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}

# Create the write Lambda function
data "archive_file" "write_lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/write_function.zip"

  source {
    content  = <<EOF
exports.handler = async (event) => {
  const AWS = require('aws-sdk');
  const documentClient = new AWS.DynamoDB.DocumentClient();
  const tableName = process.env.DYNAMODB_TABLE;

  try {
    // Parse the request body
    let body;
    try {
      body = JSON.parse(event.body);
    } catch (e) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Invalid request body' })
      };
    }

    // Validate the request body
    if (!body.id || !body.data) {
      return {
        statusCode: 400,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ error: 'Missing required fields: id and data' })
      };
    }

    // Handle different HTTP methods
    if (event.httpMethod === 'POST' || event.httpMethod === 'PUT') {
      // Generate timestamp
      const timestamp = new Date().toISOString();

      // Prepare the item for DynamoDB
      const item = {
        id: body.id,
        timestamp: timestamp,
        data: body.data
      };

      // Write to DynamoDB
      const params = {
        TableName: tableName,
        Item: item
      };

      await documentClient.put(params).promise();

      return {
        statusCode: 201,
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(item)
      };
    } 
    else if (event.httpMethod === 'DELETE') {
      // For DELETE, we need both id and timestamp
      if (!event.pathParameters || !event.pathParameters.id) {
        return {
          statusCode: 400,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ error: 'Missing id parameter' })
        };
      }

      const id = event.pathParameters.id;
      
      // If timestamp is provided in the query string parameters, delete specific item
      if (event.queryStringParameters && event.queryStringParameters.timestamp) {
        const timestamp = event.queryStringParameters.timestamp;

        const params = {
          TableName: tableName,
          Key: {
            id: id,
            timestamp: timestamp
          }
        };

        await documentClient.delete(params).promise();

        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ message: 'Item deleted successfully' })
        };
      } 
      // Otherwise, query for all items with the given ID and delete them
      else {
        // First, query all items with the given ID
        const queryParams = {
          TableName: tableName,
          KeyConditionExpression: 'id = :id',
          ExpressionAttributeValues: {
            ':id': id
          }
        };

        const result = await documentClient.query(queryParams).promise();

        // If no items found, return 404
        if (result.Items.length === 0) {
          return {
            statusCode: 404,
            headers: {
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ error: 'Item not found' })
          };
        }

        // Delete each item
        const deletePromises = result.Items.map(item => {
          const deleteParams = {
            TableName: tableName,
            Key: {
              id: item.id,
              timestamp: item.timestamp
            }
          };

          return documentClient.delete(deleteParams).promise();
        });

        await Promise.all(deletePromises);

        return {
          statusCode: 200,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify({ message: 'Deleted items successfully' })
        };
      }
    }

    // If not a supported method
    return {
      statusCode: 405,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Method not allowed' })
    };
  } catch (error) {
    console.error('Error:', error);
    
    return {
      statusCode: 500,
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ error: 'Internal server error' })
    };
  }
};
EOF
    filename = "index.js"
  }
}

resource "aws_lambda_function" "write_function" {
  function_name    = "lfre-lambda-write-${var.app_name}-${var.environment}-${var.resource_version}"
  filename         = data.archive_file.write_lambda_zip.output_path
  source_code_hash = data.archive_file.write_lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs18.x"
  timeout          = 10
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE = var.dynamodb_table_name
    }
  }
}
