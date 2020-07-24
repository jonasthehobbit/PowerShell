[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$webhook,
  [Parameter(Mandatory)]
  [string]$computername,
  [Parameter(Mandatory)]
  [string]$taskSequence
)

process {
  try {

    $messageTitle = "SCCM Allert - Please review"
    $messageBody = "Task sequence $taskSequence triggered an alert on $computername"
    $BodyTemplate = @{
      "@context"      = "https://schema.org/extensions"
      '@type'         = "MessageCard"
      themeColor      = "0072C6"
      title           = $messageTitle
      text            = $messageBody
    }
    $jsonBody = $BodyTemplate | convertto-json -ErrorAction Stop
    Invoke-RestMethod -uri $TeamsChannelUri -Method Post -body $jsonBody -ContentType 'application/json' -ErrorAction Stop
  }
  Catch {
    Write-Warning $Error[0]
  }
}

