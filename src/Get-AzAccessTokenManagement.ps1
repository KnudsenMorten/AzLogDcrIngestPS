function Get-AzAccessTokenManagement {
    [CmdletBinding()]
    param(
        [string]$AzAppId,
        [string]$AzAppSecret,
        [string]$TenantId,
        [string]$AzAppCertificateThumbprint,
        [ValidateSet('CurrentUser','LocalMachine')]
        [string]$AzAppCertificateStoreLocation = 'LocalMachine',
        [switch]$UseManagedIdentity,
        [string]$ManagedIdentityClientId
    )

    $token = Get-AzTokenForResource `
        -ResourceUrl 'https://management.azure.com/' `
        -AzAppId $AzAppId `
        -AzAppSecret $AzAppSecret `
        -TenantId $TenantId `
        -AzAppCertificateThumbprint $AzAppCertificateThumbprint `
        -AzAppCertificateStoreLocation $AzAppCertificateStoreLocation `
        -UseManagedIdentity:$UseManagedIdentity `
        -ManagedIdentityClientId $ManagedIdentityClientId

    return @{
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
        'Authorization' = "Bearer $token"
    }
}

