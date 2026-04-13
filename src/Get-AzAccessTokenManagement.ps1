function Get-AzAccessTokenManagement {
    [CmdletBinding()]
    param(
        [string]$AzAppId,
        [string]$AzAppSecret,
        [string]$TenantId,
        [switch]$UseManagedIdentity,
        [string]$ManagedIdentityClientId
    )

    $token = Get-AzTokenForResource `
        -ResourceUrl 'https://management.azure.com/' `
        -AzAppId $AzAppId `
        -AzAppSecret $AzAppSecret `
        -TenantId $TenantId `
        -UseManagedIdentity:$UseManagedIdentity `
        -ManagedIdentityClientId $ManagedIdentityClientId

    return @{
        'Content-Type'  = 'application/json'
        'Accept'        = 'application/json'
        'Authorization' = "Bearer $token"
    }
}

