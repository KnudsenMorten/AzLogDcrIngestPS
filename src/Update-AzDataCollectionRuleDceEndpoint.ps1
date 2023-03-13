Function Update-AzDataCollectionRuleDceEndpoint
{
 <#
    .SYNOPSIS
    Updates the DceEndpointUri of the Data Collection Rule

    .DESCRIPTION
    Used to change the Data Collection Endpoint in a Data Collection Rule

    .VERSION
    1.0

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER DcrResourceId
    This is resource id of the Data Collection Rule which should be changed

    .PARAMETER DceResourceId
    This is resource id of the Data Collection Endpoint to change to (target)

    .PARAMETER AzAppId
    This is the Azure app id og an app with Contributor permissions in LogAnalytics + Resource Group for DCRs
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Output of REST PUT command. Should be 200 for success

    .EXAMPLE
    $TableName                                       = 'InvClientComputerOSInfoTest4V2'   # must not contain _CL
    $DcrName                                         = "dcr-" + $AzDcrPrefixClient + "-" + $TableName + "_CL"

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $DceName                                         = "dce-log-platform-management-client-demo1-p" 
    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 

    $AzDcrPrefixClient                               = "clt1" 
    $AzDcrSetLogIngestApiAppPermissionsDcrLevel      = $false
    $AzDcrLogIngestServicePrincipalObjectId          = "xxxxxx" 

    $AzLogDcrTableCreateFromReferenceMachine         = @()
    $AzLogDcrTableCreateFromAnyMachine               = $true


    # building global variable with all DCEs, which can be viewed by Log Ingestion app
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
    # building global variable with all DCRs, which can be viewed by Log Ingestion app
    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    # make sure the DCR & DCE actually exists
    $DcrName        = "dcr-clt1-InvClientComputerOSInfoTest5V2_CL"
    $DceNameTarget  = "dce-log-platform-management-client-demo1-p" 

    # Get details about DCR using Azure Resource Graph
    $AzDcrDetails      = Get-AzDcrDceDetails -DcrName $DcrName -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$verbose
    
    # check that it found a DCR
    $AzDcrDetails
    $DcrResourceId     = $AzDcrDetails[0]
    $DcrResourceId


    # check that it found a DCR
    $AzDceDetails      = Get-AzDcrDceDetails -DceName $DceNameTarget -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$verbose
    $AzDceDetails
    $DceResourceId     = $AzDceDetails[0]
    $DceResourceId

    # update data collection endpoint - getting details about DCE using Azure Resource Graph
    Update-AzDataCollectionRuleDceEndpoint -DcrResourceId $DcrResourceId -DceResourceId $DceResourceId -Verbose:$verbose

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 4797-byte response of content type application/json; charset=utf-8
    Updating DCE EndpointId for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest5V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4769-byte response of content type application/json; charset=utf-8

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
            [Parameter(mandatory)]
                [string]$DceResourceId,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )
  
    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

    #--------------------------------------------------------------------------
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method GET -Headers $headers

    #--------------------------------------------------------------------------
    # update payload object
    #--------------------------------------------------------------------------

        $DCR.properties.dataCollectionEndpointId = $DceResourceId

    #--------------------------------------------------------------------------
    # update existing DCR
    #--------------------------------------------------------------------------

        Write-host "Updating DCE EndpointId for DCR"
        Write-host $DcrResourceId

        # convert modified payload to JSON-format
        $DcrPayload = $Dcr | ConvertTo-Json -Depth 20

        # update changes to existing DCR
        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers

}

