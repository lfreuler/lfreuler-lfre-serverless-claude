# LFRE Serverless Data Service

A cloud-native serverless application on AWS that provides a RESTful API for reading and writing data to a DynamoDB table, following the LFRE (Lambda Function REsource) pattern.

## Project Overview

This project implements a complete serverless data service that includes:

- Lambda functions for reading and writing data to a DynamoDB table
- API Gateway with API Key authentication to securely access the functions
- DynamoDB table with a simple key-value structure
- PowerShell scripts for interacting with the API

The infrastructure is defined as code using Terraform, with modular configurations that support multiple environments (dev, test, prod).

## Architecture

- **DynamoDB Table**: Stores application data with `id` as the partition key and `timestamp` as the sort key
- **Lambda Functions**:
  - Read Function: Retrieves data from DynamoDB
  - Write Function: Writes data to DynamoDB, including create, update, and delete operations
- **API Gateway**:
  - Provides HTTP endpoints with API Key authentication
  - Supports the following operations:
    - `GET /items?id={id}` - Retrieve item(s) by ID
    - `GET /items` - List all items (paginated)
    - `POST /items` - Create a new item
    - `PUT /items/{id}` - Update an existing item
    - `DELETE /items/{id}` - Delete item(s)

## Resource Naming Convention

All resources follow the naming convention: `lfre-<type>-(<subtype>)-<appname>-<env>-(<version>)`

## Deployment

### Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- PowerShell 7.0+ (for running the scripts)

### Deployment Steps

1. Initialize Terraform for the desired environment:
   ```bash
   cd terraform/environments/dev
   terraform init -backend-config=backend.tfvars
   ```

2. Plan the deployment:
   ```bash
   terraform plan -var-file=terraform.tfvars
   ```

3. Apply the changes:
   ```bash
   terraform apply -var-file=terraform.tfvars
   ```

4. Retrieve the API endpoint and key from Terraform outputs.

## Usage

### Reading Data

```powershell
./scripts/Read-DataFromApi.ps1 -ApiEndpoint "https://api-id.execute-api.region.amazonaws.com/dev" -ApiKey "your-api-key" -ItemId "item123"
```

### Writing Data

```powershell
$data = @{
    name = "Example Item"
    value = 42
    attributes = @{
        color = "blue"
        size = "medium"
    }
}

./scripts/Write-DataToApi.ps1 -ApiEndpoint "https://api-id.execute-api.region.amazonaws.com/dev" -ApiKey "your-api-key" -ItemId "item123" -ItemData $data
```

## License

This project is licensed under the MIT License.