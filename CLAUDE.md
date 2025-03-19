# LFRE Serverless Data Service

## Project Description

This project implements a cloud-native serverless application on AWS that provides a RESTful API for reading and writing data to a DynamoDB table. The application follows the LFRE (Lambda Function REsource) pattern and uses modular Terraform configurations to provision all required resources.

The application consists of:
- Lambda functions for reading and writing data from a DynamoDB table
- API Gateway with API key authentication to securely access the functions
- PowerShell scripts for interacting with the API

## File Structure

```
lfre-data-service/
├── README.md
├── CLAUDE.md
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── providers.tf
│   ├── backend.tf
│   ├── modules/
│   │   ├── api_gateway/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   ├── lambda/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   └── outputs.tf
│   │   └── dynamodb/
│   │       ├── main.tf
│   │       ├── variables.tf
│   │       └── outputs.tf
│   └── environments/
│       ├── dev/
│       │   ├── main.tf
│       │   ├── terraform.tfvars
│       │   └── backend.tfvars
│       ├── test/
│       │   ├── main.tf
│       │   ├── terraform.tfvars
│       │   └── backend.tfvars
│       └── prod/
│           ├── main.tf
│           ├── terraform.tfvars
│           └── backend.tfvars
└── scripts/
    ├── Read-DataFromApi.ps1
    └── Write-DataToApi.ps1
```

## Resource Naming Convention

All resources follow the naming convention:

```
lfre-<type>-(<subtype>)-<appname>-<env>-(<version>)
```

Where:
- `<type>`: Resource type (lambda, api, dynamo, etc.)
- `<subtype>`: Optional subtype specification
- `<appname>`: Application name (dataservice)
- `<env>`: Environment (dev, test, prod)
- `<version>`: Optional version identifier

### Examples:
- Lambda Function: `lfre-lambda-read-dataservice-dev-v1`
- API Gateway: `lfre-api-dataservice-dev-v1`
- DynamoDB Table: `lfre-dynamo-dataservice-dev-v1`
- IAM Role: `lfre-role-lambda-dataservice-dev-v1`

## Resource Tagging

All resources are tagged with:
- `lfre_owner`: Owner of the resource
- `lfre_managedby`: Managed by information (usually "Terraform")
- `lfre_environment`: Environment (dev, test, prod)

## Infrastructure Components

### DynamoDB Table

The DynamoDB table stores the application data with a simple key-value structure:

- Table Name: `lfre-dynamo-dataservice-<env>-v1`
- Primary Key: `id` (String)
- Sort Key: `timestamp` (String)

### Lambda Functions

Two Lambda functions handle data operations:

1. **Read Function**
   - Name: `lfre-lambda-read-dataservice-<env>-v1`
   - Purpose: Retrieves data from the DynamoDB table
   - Execution Role: `lfre-role-lambda-dataservice-<env>-v1`
   - Runtime: Node.js 18.x

2. **Write Function**
   - Name: `lfre-lambda-write-dataservice-<env>-v1`
   - Purpose: Writes data to the DynamoDB table
   - Execution Role: `lfre-role-lambda-dataservice-<env>-v1`
   - Runtime: Node.js 18.x

### API Gateway

The API Gateway provides HTTP endpoints to interact with the Lambda functions:

- Name: `lfre-api-dataservice-<env>-v1`
- Stage: `<env>`
- Authentication: API Key
- API Key Name: `lfre-apikey-dataservice-<env>-v1`
- Usage Plan Name: `lfre-usageplan-dataservice-<env>-v1`

#### Endpoints

- `GET /items?id={id}` - Retrieve an item by ID
- `GET /items` - List all items
- `POST /items` - Create a new item
- `PUT /items/{id}` - Update an existing item
- `DELETE /items/{id}` - Delete an item

## Terraform Implementation

### Modules

The Terraform configuration is organized into reusable modules:

1. **DynamoDB Module**
   - Creates and configures the DynamoDB table
   - Handles capacity settings (on-demand or provisioned)
   - Sets up auto-scaling if needed

2. **Lambda Module**
   - Creates Lambda functions with appropriate permissions
   - Sets up CloudWatch logs
   - Configures environment variables

3. **API Gateway Module**
   - Creates REST API in API Gateway
   - Sets up API key and usage plan
   - Configures routes and integrations with Lambda functions

### Environment Configuration

Each environment (dev, test, prod) has its own Terraform configuration that:
- Uses the shared modules
- Specifies environment-specific variables
- Configures remote state storage

## API Usage

### Authentication

All API requests must include the API key in the `x-api-key` header.

### Request/Response Format

The API accepts and returns JSON data in the following format:

**Request Body Example (POST/PUT):**
```json
{
  "id": "item123",
  "data": {
    "name": "Example Item",
    "value": 42,
    "attributes": {
      "color": "blue",
      "size": "medium"
    }
  }
}
```

**Response Example (GET):**
```json
{
  "id": "item123",
  "timestamp": "2025-03-19T10:15:30Z",
  "data": {
    "name": "Example Item",
    "value": 42,
    "attributes": {
      "color": "blue",
      "size": "medium"
    }
  }
}
```

## PowerShell Scripts

### Read-DataFromApi.ps1

This script retrieves data from the API:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiEndpoint,
    
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$false)]
    [string]$ItemId
)

$headers = @{
    "x-api-key" = $ApiKey
    "Content-Type" = "application/json"
}

if ($ItemId) {
    $url = "$ApiEndpoint/items?id=$ItemId"
} else {
    $url = "$ApiEndpoint/items"
}

try {
    $response = Invoke-RestMethod -Uri $url -Method Get -Headers $headers
    return $response
} catch {
    Write-Error "Error retrieving data: $_"
}
```

### Write-DataToApi.ps1

This script writes data to the API:

```powershell
param(
    [Parameter(Mandatory=$true)]
    [string]$ApiEndpoint,
    
    [Parameter(Mandatory=$true)]
    [string]$ApiKey,
    
    [Parameter(Mandatory=$true)]
    [string]$ItemId,
    
    [Parameter(Mandatory=$true)]
    [hashtable]$ItemData
)

$headers = @{
    "x-api-key" = $ApiKey
    "Content-Type" = "application/json"
}

$body = @{
    id = $ItemId
    data = $ItemData
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$ApiEndpoint/items" -Method Post -Headers $headers -Body $body
    Write-Output "Successfully written data with ID: $ItemId"
    return $response
} catch {
    Write-Error "Error writing data: $_"
}
```

## Deployment

### Prerequisites

- Terraform >= 1.0.0
- AWS CLI configured with appropriate credentials
- PowerShell 7.0+ (for running the scripts)

### Deployment Process

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

## Usage Examples

### Reading Data

```powershell
./scripts/Read-DataFromApi.ps1 -ApiEndpoint "https://api-id.execute-api.eu-west-1.amazonaws.com/dev" -ApiKey "your-api-key" -ItemId "item123"
```

### Writing Data

```powershell
$data = @{
    name = "New Item"
    value = 100
    attributes = @{
        color = "red"
        size = "large"
    }
}

./scripts/Write-DataToApi.ps1 -ApiEndpoint "https://api-id.execute-api.eu-west-1.amazonaws.com/dev" -ApiKey "your-api-key" -ItemId "item456" -ItemData $data
```
