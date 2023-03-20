Function Update-AzDataCollectionRuleTransformKql
{
 <#
    .SYNOPSIS
    Updates the tranformKql parameter on an existing DCR with the provided parameter

    .DESCRIPTION
    Used to enable transformation on a data collection rule

    .PARAMETER $DcrResourceId
    This is the resource id of the data collection rule

    .PARAMETER $tranformKql
    This is tranformation query to use

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

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    $Verbose = $true

    # make a DCR Event Log collection of security events - can be done through Sentinel
    $DcrResourceId = "/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-ingest-exclude-security-eventid"

    # Remove transformation - send all data through pipeline
    $transformKql = "source"

    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$Verbose

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 1419-byte response of content type application/json; charset=utf-8
    Updating transformKql for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-i
    ngest-exclude-security-eventid
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 1419-byte response of content type application/json; charset=utf-8

    # Add transformation to exclude event 8002, 5058, 4662, 4688
    $transformKql = "source | where (EventID != 8002) and (EventID != 5058) and (EventID != 4662) and (EventID != 4688)"

    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$true

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 1511-byte response of content type application/json; charset=utf-8
    Updating transformKql for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-i
    ngest-exclude-security-eventid
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 1511-byte response of content type application/json; charset=utf-8
	

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
            [Parameter(mandatory)]
                [string]$transformKql,
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
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method GET -Headers $Headers

    #--------------------------------------------------------------------------
    # update payload object
    #--------------------------------------------------------------------------

        If ($DCR.properties.dataFlows[0].transformKql)
            {
                # changing value on existing property
                $DCR.properties.dataFlows[0].transformKql = $transformKql
            }
        Else
            {
                # Adding new property to object
                $DCR.properties.dataFlows[0] | Add-Member -NotePropertyName transformKql -NotePropertyValue $transformKql -Force
            }


    #--------------------------------------------------------------------------
    # update existing DCR
    #--------------------------------------------------------------------------

        Write-host "Updating transformKql for DCR"
        Write-host $DcrResourceId

        # convert modified payload to JSON-format
        $DcrPayload = $Dcr | ConvertTo-Json -Depth 20

        # update changes to existing DCR
        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers

}
