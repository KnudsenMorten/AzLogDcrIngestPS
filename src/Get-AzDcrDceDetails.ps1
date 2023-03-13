Function Get-AzDcrDceDetails
{
 <#
    .SYNOPSIS
    Retrieves information about data collection rules and data collection endpoints - using Azure Resource Graph

    .DESCRIPTION
    Used to retrieve information about data collection rules and data collection endpoints - using Azure Resource Graph
    Used by other functions which are looking for DCR/DCE by name

    .VERSION
    1.0

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER DcrName
    Here you can put in the DCR name you want to find

    .PARAMETER DceName
    Here you can put in the DCE name you want to find

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Information about DCR/DCE

    .EXAMPLE
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $DceName                                         = "dce-log-platform-management-client-demo1-p" 
    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 
    $AzDcrPrefixClient                               = "clt1" 

    $AzDcrSetLogIngestApiAppPermissionsDcrLevel      = $false
    $AzDcrLogIngestServicePrincipalObjectId          = "xxxxxx" 

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
            
    Write-Output ""
    Write-Output "Collecting OS information ... Please Wait !"

    $DataVariable = Get-CimInstance -ClassName Win32_OperatingSystem

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

    # convert CIM array to PSCustomObject and remove CIM class information
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose
    
    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose

    # add Computer & UserLoggedOn info to existing array
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName  -Column2Name UserLoggedOn -Column2Data $UserLoggedOn

    # Validating/fixing schema data structure of source data
    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

    # Aligning data structure with schema (requirement for DCR)
    $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose

    # We change the tablename to something - for example add TEST (InvClientComputerOSInfoTESTV2) - table doesn't exist
    $TableName = 'InvClientComputerOSInfoTESTV2'   # must not contain _CL
    $DcrName   = "dcr-" + $AzDcrPrefixClient + "-" + $TableName + "_CL"

    $Schema = Get-ObjectSchemaAsArray -Data $DataVariable
    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                        -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

    # build schema to be used for DCR
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType DCR

    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose



    $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName -DceName $DceName `
                                            -AzAppId $LogIngestAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

    # required information is returned in the stream as variables $AzDcrDceDetails[0], $AzDcrDceDetails[1], etc
    $AzDcrDceDetails

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-demo1-p/providers/Microsoft.Insig
    hts/dataCollectionEndpoints/dce-log-platform-management-client-demo1-p
    westeurope
    https://dce-log-platform-management-client-demo1-p-c5hl.westeurope-1.ingest.monitor.azure.com
    dce-7a8a2d176844444b9e89719b702dccec
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTESTV2_CL
    westeurope
    dcr-0189d991f81f43efbcfb6fc520541452
    Custom-InvClientComputerOSInfoTESTV2_CL
    log-platform-management-client-demo1-p
    e74ca75a-c0e6-4933-a4f7-e5ae943fe4ac
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log
    -platform-management-client-demo1-p
    source | extend TimeGenerated = now()

 #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$DceName,
            [Parameter()]
                [string]$DcrName,
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
    # Get DCEs from Azure Resource Graph
    #--------------------------------------------------------------------------
        
        If ($DceName)
            {
                If ($global:AzDceDetails)   # global variables was defined. Used to mitigate throttling in Azure Resource Graph (free service)
                    {
                        # Retrieve DCE in scope
                        $DceInfo = $global:AzDceDetails | Where-Object { $_.name -eq $DceName }
                            If (!($DceInfo))
                                {
                                    # record not found - rebuild list and try again
                                    Write-Output "DCE name was not found in index ... fallback to Azure Resource Graph query !"
                                    
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

                                    # Retrieve DCE in scope
                                    $DceInfo = $Data | Where-Object { $_.name -eq $DceName }
                                        If (!($DceInfo))
                                            {
                                                Write-Output "Could not find DCE with name [ $($DceName) ]"
                                            }
                                }
                    }
                Else
                    {
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

                        # Retrieve DCE in scope
                        $DceInfo = $Data | Where-Object { $_.name -eq $DceName }
                            If (!($DceInfo))
                                {
                                    Write-Output "Could not find DCE with name [ $($DceName) ]"
                                }
                    }
            }

    #--------------------------------------------------------------------------
    # Get DCRs from Azure Resource Graph
    #--------------------------------------------------------------------------

        If ($DcrName)
            {
                If ($global:AzDcrDetails)   # global variables was defined. Used to mitigate throttling in Azure Resource Graph (free service)
                    {
                        # Retrieve DCE in scope
                        $DcrInfo = $global:AzDcrDetails | Where-Object { $_.name -eq $DcrName }
                            If (!($DcrInfo))
                                {
                                    Write-Output "DCR name was not found in index ... fallback to Azure Resource Graph query !"
                                    
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
    
                                    $DcrInfo = $Data | Where-Object { $_.name -eq $DcrName }
                                       If (!($DcrInfo))
                                        {
                                            Write-Output "Could not find DCR with name [ $($DcrName) ]"
                                        }
                                }
                    }
                Else
                    {
                        $AzGraphQuery = @{
                                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionrules" '
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

                        $DcrInfo = $Data | Where-Object { $_.name -eq $DcrName }
                            If (!($DcrInfo))
                                {
                                    Write-Output "Could not find DCR with name [ $($DcrName) ]"
                                }
                    }
            }

    #--------------------------------------------------------------------------
    # values
    #--------------------------------------------------------------------------
        If ( ($DceName) -and ($DceInfo) )
            {
                $DceResourceId                                  = $DceInfo.id
                $DceLocation                                    = $DceInfo.location
                $DceURI                                         = $DceInfo.properties.logsIngestion.endpoint
                $DceImmutableId                                 = $DceInfo.properties.immutableId

                # return / output
                $DceResourceId
                $DceLocation
                $DceURI
                $DceImmutableId
            }

        If ( ($DcrName) -and ($DcrInfo) )
            {
                $DcrResourceId                                  = $DcrInfo.id
                $DcrLocation                                    = $DcrInfo.location
                $DcrImmutableId                                 = $DcrInfo.properties.immutableId
                $DcrStream                                      = $DcrInfo.properties.dataflows.outputStream
                $DcrDestinationsLogAnalyticsWorkSpaceName       = $DcrInfo.properties.destinations.logAnalytics.name
                $DcrDestinationsLogAnalyticsWorkSpaceId         = $DcrInfo.properties.destinations.logAnalytics.workspaceId
                $DcrDestinationsLogAnalyticsWorkSpaceResourceId = $DcrInfo.properties.destinations.logAnalytics.workspaceResourceId
                $DcrTransformKql                                = $DcrInfo.properties.dataFlows[0].transformKql


                # return / output
                $DcrResourceId
                $DcrLocation
                $DcrImmutableId
                $DcrStream
                $DcrDestinationsLogAnalyticsWorkSpaceName
                $DcrDestinationsLogAnalyticsWorkSpaceId
                $DcrDestinationsLogAnalyticsWorkSpaceResourceId
                $DcrTransformKql
            }

        return
}
