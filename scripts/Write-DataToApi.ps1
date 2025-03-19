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
