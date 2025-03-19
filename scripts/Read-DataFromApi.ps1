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
