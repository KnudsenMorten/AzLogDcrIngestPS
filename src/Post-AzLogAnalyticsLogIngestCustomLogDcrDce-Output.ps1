function Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output {
<#
    .SYNOPSIS
    Send data to LogAnalytics using Log Ingestion API and Data Collection Rule (combined).

    .DESCRIPTION
    Combined function that wraps Get-AzDcrDceDetails and Post-AzLogAnalyticsLogIngestCustomLogDcrDce.

    Supports gzip compression and Azure Managed Identity, configured either globally
    via $global:EnableCompressionDefault / $global:UseManagedIdentityDefault, or per
    call via -EnableCompression / -UseManagedIdentity.

    Priority: per-call parameter > global default > off.

    .PARAMETER EnableCompression
    Enables gzip compression ($true / $false / $null).
    $null = use $global:EnableCompressionDefault. If global not set, compression is off.

    .PARAMETER UseManagedIdentity
    Uses Managed Identity authentication ($true / $false / $null).
    $null = use $global:UseManagedIdentityDefault. If global not set, managed identity is off.

    .PARAMETER ManagedIdentityClientId
    Client ID of user-assigned managed identity. Only needed for user-assigned (not system-assigned).

    .PARAMETER BatchAmount
    Forces a specific number of records per batch. Overrides automatic 1 MB batch sizing.

    .EXAMPLE
    # Global defaults   set once, applies to all calls
    $global:EnableCompressionDefault  = $true
    $global:UseManagedIdentityDefault = $false

    Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName `
        -Data $DataVariable -TableName $TableName `
        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId

    .EXAMPLE
    # Per-call override
    Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName `
        -Data $DataVariable -TableName $TableName `
        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId `
        -EnableCompression $true

    .EXAMPLE
    # Managed Identity with compression
    Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName `
        -Data $DataVariable -TableName $TableName `
        -UseManagedIdentity $true -EnableCompression $true
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Data,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$DcrName,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$DceName,

        [Parameter(Mandatory)]
        [string]$TableName,

        [string]$BatchAmount,
        [bool]$EnableUploadViaLogHub = $false,
        [string]$LogHubPath,
        [string]$AzAppId,
        [string]$AzAppSecret,
        [string]$AzAppCertificateThumbprint,
        [ValidateSet('CurrentUser','LocalMachine')]
        [string]$AzAppCertificateStoreLocation = 'LocalMachine',
        [string]$TenantId,

        [Nullable[bool]]$EnableCompression = $null,
        [Nullable[bool]]$UseManagedIdentity = $null,
        [string]$ManagedIdentityClientId
    )

    if ($EnableCompression -eq $null) {
        $EnableCompression = if ($null -ne $global:EnableCompressionDefault) { $global:EnableCompressionDefault } else { $false }
    }

    if ($UseManagedIdentity -eq $null) {
        $UseManagedIdentity = if ($null -ne $global:UseManagedIdentityDefault) { $global:UseManagedIdentityDefault } else { $false }
    }

    if (($EnableUploadViaLogHub -eq $false) -or ($null -eq $EnableUploadViaLogHub)) {

        $azDcrDceDetails = Get-AzDcrDceDetails `
            -DcrName $DcrName `
            -DceName $DceName `
            -AzAppId $AzAppId `
            -AzAppSecret $AzAppSecret `
            -AzAppCertificateThumbprint $AzAppCertificateThumbprint `
            -AzAppCertificateStoreLocation $AzAppCertificateStoreLocation `
            -TenantId $TenantId `
            -Verbose:$VerbosePreference

        return (Post-AzLogAnalyticsLogIngestCustomLogDcrDce `
            -DceUri $azDcrDceDetails[2] `
            -DcrImmutableId $azDcrDceDetails[6] `
            -TableName $TableName `
            -DcrStream $azDcrDceDetails[7] `
            -Data $Data `
            -BatchAmount $BatchAmount `
            -AzAppId $AzAppId `
            -AzAppSecret $AzAppSecret `
            -AzAppCertificateThumbprint $AzAppCertificateThumbprint `
            -AzAppCertificateStoreLocation $AzAppCertificateStoreLocation `
            -TenantId $TenantId `
            -EnableCompression $EnableCompression `
            -UseManagedIdentity $UseManagedIdentity `
            -ManagedIdentityClientId $ManagedIdentityClientId `
            -Verbose:$VerbosePreference)
    }

    if (($EnableUploadViaLogHub -eq $true) -and $LogHubPath -and $Data) {
        $logHubData = [pscustomobject]@{
            Source     = $env:ComputerName
            UploadTime = (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')
            TableName  = $TableName
            DceName    = $DceName
            DcrName    = $DcrName
            Data       = @($Data)
        }

        if ($BatchAmount) {
            $logHubData | Add-Member -MemberType NoteProperty -Name BatchAmount -Value $BatchAmount
        }

        if ($EnableCompression -eq $true) {
            $logHubData | Add-Member -MemberType NoteProperty -Name EnableCompression -Value $true
        }

        if ($UseManagedIdentity -eq $true) {
            $logHubData | Add-Member -MemberType NoteProperty -Name UseManagedIdentity -Value $true
        }

        if ($ManagedIdentityClientId) {
            $logHubData | Add-Member -MemberType NoteProperty -Name ManagedIdentityClientId -Value $ManagedIdentityClientId
        }

        $logHubFileName = Join-Path $LogHubPath ($env:ComputerName + '__' + $TableName + '__' + (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss') + '.json')
        Write-Host "Writing log-data to file $logHubFileName (log-hub)"

        $logHubData | ConvertTo-Json -Depth 25 | Out-File -FilePath $logHubFileName -Encoding utf8 -Force
    }
}

