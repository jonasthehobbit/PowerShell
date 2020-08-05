[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [SecureString]$password,
    [Parameter(Mandatory)]
    [String]$years,
    [Parameter(Mandatory)]
    [String]$DisplayName
)
function Get-AccessToken {
    $context = Get-AzContext
    $profile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($profile)
    $token = $profileClient.AcquireAccessToken($context.Subscription.TenantId)
    return $token.AccessToken
}
process {
    try {
        # Login to Azure AD PowerShell With Admin Account (you need to be Azure AD admin to create the cert) 
        Connect-AzAccount -ErrorAction stop
        Import-Module -Name Az.Resources -ErrorAction stop
        # Create the self signed cert and export
        $currentDate = Get-Date -ErrorAction stop
        $endDate = $currentDate.AddYears($years)
        $notAfter = $endDate.AddYears($years)
        $thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -DnsName $DisplayName -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter -ErrorAction stop).Thumbprint
        Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath c:\temp\$DisplayName.pfx -Password $password
        # Load the certificate
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\temp\$DisplayName.pfx", $password) -ErrorAction stop
        $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
        # Create the Service Principal with certificate auth
        $sp = New-AzAdServicePrincipal -DisplayName $DisplayName -CertValue $keyValue -EndDate $endDate -StartDate $currentDate -ErrorAction stop
        # Get Tenant Detail
        $tenant = Get-AzTenant -ErrorAction stop
        # Get bearer token for Graph API from current login creds
    }
    Catch {
        Write-Warning $Error[0]
    }
    Finally {
        # Now you can login to Azure PowerShell with your Service Principal and Certificate
        Write-Host -ForegroundColor blue "You connection string is:
        Connect-AzureAD -TenantId $($Tenant.id) -ApplicationId $($sp.ApplicationId) -CertificateThumbprint $($thumb)
        Please do not include the App ID and Thumbprint in plain text in your script"
    }
}