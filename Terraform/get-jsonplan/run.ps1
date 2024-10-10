# Define variables
param (
    [Parameter(mandatory=$true)]
    [string]$organization,
    [Parameter(mandatory=$true)]
    [string]$workspace_id
)
$tf_api_token = gc $env:APPDATA\terraform.d\credentials.tfrc.json | ConvertFrom-Json
$apiToken = $tf_api_token.credentials.'app.terraform.io'.token
if (!(Test-Path $env:APPDATA\terraform.d\credentials.tfrc.json)) {
    Write-Error "Terraform CLI credentials file not found."
    exit 1
}

$apiUri = "https://app.terraform.io/api/v2"

# Function to get the latest run ID for the specified workspace
function Get-LatestRunId {
    param (
        [string]$organization,
        [string]$workspace_id,
        [string]$apiToken
    )

    $headers = @{
        "Authorization" = "Bearer $apiToken"
        "Content-Type"  = "application/vnd.api+json"
    }

    $url = "$apiUri/workspaces/$workspace_id/runs"
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    if ($response.data.Count -eq 0) {
        Write-Error "No runs found for workspace $workspace"
        return $null
    }
    return $response.data[0].id
}

# Function to get the JSON plan file for the specified run ID
function Get-JsonPlan {
    param (
        [string]$runId,
        [string]$apiToken
    )

    $headers = @{
        "Authorization" = "Bearer $apiToken"
        "Content-Type"  = "application/vnd.api+json"
    }

    $url = "$apiUri/runs/$runId/plan/json-output"
    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    return $response
}

# Main script
$runId = Get-LatestRunId -organization $organization -workspace $workspace_id -apiToken $apiToken

if ($runId) {
    $jsonPlan = Get-JsonPlan -runId $runId -apiToken $apiToken
    $jsonPlan | ConvertTo-Json -Depth 100 | Out-File .\latest-plan.json
} else {
    Write-Error "Failed to retrieve the latest run ID."
}