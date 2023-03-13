Function Get-AzDceListAll
{
  <#
    .SYNOPSIS
    Builds list of all Data Collection Endpoints (DCEs), which can be retrieved by Azure using the RBAC context of the Log Ingestion App

    .DESCRIPTION
    Data is retrieved using Azure Resource Graph
    Result is saved in global-variable in Powershell
    Main reason for saving as global-variable is to optimize number of times to do lookup - due to throttling in Azure Resource Graph

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Build data array
    #-------------------------------------------------------------------------------------------

    # building global variable with all DCEs, which can be viewed by Log Ingestion app
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
    $global:AzDceDetails

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    id               : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-demo1-p/provi
                       ders/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-demo1-p
    name             : dce-log-platform-management-client-demo1-p
    type             : microsoft.insights/datacollectionendpoints
    tenantId         : f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e
    kind             : 
    location         : westeurope
    resourceGroup    : rg-dce-log-platform-management-client-demo1-p
    subscriptionId   : fce4f282-fcc6-43fb-94d8-bf1701b862c3
    managedBy        : 
    sku              : 
    plan             : 
    properties       : @{provisioningState=Succeeded; description=DCE for LogIngest to LogAnalytics log-platform-management-client-demo1-p; n
                       etworkAcls=; immutableId=dce-7a8a2d176844444b9e89719b702dccec; configurationAccess=; logsIngestion=; metricsIngestion=
                       }
    tags             : 
    identity         : 
    zones            : 
    extendedLocation :
  #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

    Write-Verbose ""
    Write-Verbose "Getting Data Collection Endpoints from Azure Resource Graph .... Please Wait !"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

    #--------------------------------------------------------------------------
    # Get DCEs from Azure Resource Graph
    #--------------------------------------------------------------------------

        $AzGraphQuery = @{
                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionendpoints" '
                            } | ConvertTo-Json -Depth 20

        $ResponseData = @()

        $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
        $ResponseRaw         = Invoke-WebRequest -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
        $ResponseData       += $ResponseRaw.content
        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

        While ($ResponseNextLink -ne $null)
            {
                $ResponseRaw         = Invoke-WebRequest -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                $ResponseData       += $ResponseRaw.content
                $ResponseNextLink    = $ResponseRaw."@odata.nextLink"
            }
        $DataJson = $ResponseData | ConvertFrom-Json
        $Data     = $DataJson.data

        Return $Data
}
