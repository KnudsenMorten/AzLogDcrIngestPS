Function CreateUpdate-AzLogAnalyticsCustomLogTableDcr {
  <#
    .SYNOPSIS
    Create or Update Azure LogAnalytics Custom Log table - used together with Data Collection Rules (DCR)
    for Log Ingestion API upload to LogAnalytics

    .DESCRIPTION
    Uses schema based on source object

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER SchemaSourceObject
    This is the schema in hash table format coming from the source object

    .PARAMETER SchemaMode
    SchemaMode = Merge (default)
    It will do a merge/union of new properties and existing schema properties. DCR will import schema from table

    SchemaMode = Overwrite
    It will overwrite existing schema in DCR/table   based on source object schema
    This parameter can be useful for separate overflow work

    SchemaMode = Migrate
    It will create the DCR, based on the schema from the LogAnalytics v1 table schema
    This parameter is used only as part of migration away from HTTP Data Collector API to Log Ingestion API

    .PARAMETER AzLogWorkspaceResourceId
    This is the Loganaytics Resource Id

    .PARAMETER AzAppId
    This is the Azure app id
        
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
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $DceName                                         = "dce-log-platform-management-client-demo1-p" 
    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 
    $AzDcrPrefixClient                               = "clt1" 

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

    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    # we see that structure is missing, so we set the flag to enforce creating both DCR and table
    $StructureCheck


    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !
    VERBOSE: GET with 0-byte payload
    VERBOSE:   LogAnalytics table wasn't found !
    VERBOSE:   DCR was not found [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ]
    $True

    # build schema to be used for LogAnalytics Table
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType Table -Verbose:$Verbose

    CreateUpdate-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaSourceObject $Schema -TableName $TableName `
                                                    -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose 

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: 
    VERBOSE: Trying to update existing LogAnalytics table schema for table [ InvClientComputerOSInfoTESTV2_CL ] in 
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PATCH with -1-byte payload
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7761-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: LogAnalytics Table doesn't exist or problems detected .... creating table [ InvClientComputerOSInfoTESTV2_CL ] in
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7761-byte response of content type application/json; charset=utf-8


    StatusCode        : 200
    StatusDescription : OK
    Content           : {"properties":{"totalRetentionInDays":30,"archiveRetentionInDays":0,"plan":"Analytics","retentionInDaysAsDefault":tru
                        e,"totalRetentionInDaysAsDefault":true,"schema":{"tableSubType":"DataCollectionRule...
    RawContent        : HTTP/1.1 200 OK
                        Pragma: no-cache
                        Request-Context: appId=cid-v1:c7ec48f5-2684-46e8-accb-45e7dbec242b
                        X-Content-Type-Options: nosniff
                        api-supported-versions: 2015-03-20, 2015-11-01-preview, 2017-01-...
    Forms             : {}
    Headers           : {[Pragma, no-cache], [Request-Context, appId=cid-v1:c7ec48f5-2684-46e8-accb-45e7dbec242b], [X-Content-Type-Options, n
                        osniff], [api-supported-versions, 2015-03-20, 2015-11-01-preview, 2017-01-01-preview, 2017-03-03-preview, 2017-03-15-
                        preview, 2017-04-26-preview, 2020-03-01-preview, 2020-08-01, 2020-10-01, 2021-03-01-privatepreview, 2021-07-01-privat
                        epreview, 2021-12-01-preview, 2022-09-01-privatepreview, 2022-10-01]...}
    Images            : {}
    InputFields       : {}
    Links             : {}
    ParsedHtml        : mshtml.HTMLDocumentClass
    RawContentLength  : 7761
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter(mandatory)]
                [array]$SchemaSourceObject,
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
            [Parameter()]
                [string]$SchemaMode = "Merge",     # Merge = Merge new properties into existing schema, Overwrite = use source object schema, Migrate = It will create the DCR, based on the schema from the LogAnalytics v1 table schema
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
    # TableCheck
    #--------------------------------------------------------------------------
        $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($TableName)_CL?api-version=2021-12-01-preview"
        $TableStatus = Try
                            {
                                invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
                            }
                        Catch
                            {
                                If ($SchemaMode -eq "Merge")
                                    {
                                        # force SchemaMode to Overwrite (create/update)
                                        $SchemaMode = "Overwrite"
                                    }
                            }

    #--------------------------------------------------------------------------
    # Compare schema between source object schema and Azure LogAnalytics Table
    #--------------------------------------------------------------------------

        If ($TableStatus)
            {
                $CurrentTableSchema = $TableStatus.properties.schema.columns
                $AzureTableSchema   = $TableStatus.properties.schema.standardColumns
            }

    #--------------------------------------------------------------------------
    # LogAnalytics Table check
    #--------------------------------------------------------------------------

        $Table         = $TableName  + "_CL"    # TableName with _CL (CustomLog)

        If ($Table.Length -gt 45)
            {
                Write-Error "ERROR - Reduce length of tablename, as it has a maximum of 45 characters (current length: $($Table.Length))"
            }

    #-----------------------------------------------------------------------------------------------
    # SchemaMode = Overwrite - Creating/Updating LogAnalytics Table based upon data source schema
    #-----------------------------------------------------------------------------------------------
    If ($SchemaMode -eq "Overwrite")
        {
            $tableBodyPut   = @{
                                    properties = @{
                                                    schema = @{
                                                                    name    = $Table
                                                                    columns = @($SchemaSourceObject)
                                                                }
                                                }
                                } | ConvertTo-Json -Depth 10

            # create/update table schema using REST
            $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($Table)?api-version=2021-12-01-preview"

            Try
                {
                    Write-Verbose ""
                    Write-Verbose "Trying to update existing LogAnalytics table schema for table [ $($Table) ] in "
                    Write-Verbose $AzLogWorkspaceResourceId

                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                }
            Catch
                {

                    Write-Verbose ""
                    Write-Verbose "Internal error 500 - recreating table"

                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method DELETE -Headers $Headers
                                
                    Start-Sleep -Seconds 10
                                
                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                }
        }

    #-----------------------------------------------------------------------------------------------
    # SchemaMode = Merge - Merging new properties into existing schema
    #-----------------------------------------------------------------------------------------------
    If ( ($SchemaMode -eq "Merge") -or ($SchemaMode -eq "Migrate") )
        {
            # start by building new schema hash, based on existing schema in LogAnalytics custom log table
                $SchemaArrayLogAnalyticsTableFormatHash = @()
                ForEach ($Property in $CurrentTableSchema)
                    {
                        $Name = $Property.name
                        $Type = $Property.type

                        If ($Name -notin $AzureTableSchema.name)   # exclude standard columns, especially important with migrated from v1 as Computer, TimeGenerated, etc. exist
                            {
                                $SchemaArrayLogAnalyticsTableFormatHash += @{
                                                                              name        = $name
                                                                              type        = $type
                                                                              description = ""
                                                                           }
                            }
                    }


            # enum $SchemaSourceObject - and check if it exists in $SchemaArrayLogAnalyticsTableFormatHash
            $UpdateTable = $False
            ForEach ($PropertySource in $SchemaSourceObject)
                {
                    If ($PropertySource.name -notin $AzureTableSchema.name)   # exclude standard columns, especially important with migrated from v1 as Computer, TimeGenerated, etc. exist
                        {
                            $PropertyFound = $false
                            ForEach ($Property in $SchemaArrayLogAnalyticsTableFormatHash)
                                {

                                    # 2023-04-25 - removed so script will only change schema if name is not found - not if property type is different (who wins?)
                                    # If ( ($Property.name -eq $PropertySource.name) -and ($Property.type -eq $PropertySource.type) )
                            
                                    If ($Property.name -eq $PropertySource.name)
                                        {
                                            $PropertyFound = $true
                                        }

                                }
                        
                            If ($PropertyFound -eq $true)
                                {
                                    # Name already found ... skipping
                                }
                            Else
                                {
                                    # table must be updated, changes detected in merge-mode
                                    $UpdateTable = $true

                                    Write-verbose "SchemaMode = Merge: Adding property $($PropertySource.name)"
                                    $SchemaArrayLogAnalyticsTableFormatHash += @{
                                                                                    name        = $PropertySource.name
                                                                                    type        = $PropertySource.type
                                                                                    description = ""
                                                                                }
                                }
                        }
                }

            If ($UpdateTable -eq $true)
                {            
                    # new table structure with added properties (merging)
                        $tableBodyPut   = @{
                                                properties = @{
                                                                schema = @{
                                                                                name    = $Table
                                                                                columns = @($SchemaArrayLogAnalyticsTableFormatHash)
                                                                            }
                                                            }
                                           } | ConvertTo-Json -Depth 10

                        $tableBodyPutFull   = @{
                                                properties = @{
                                                                schema = @{
                                                                                name    = $Table
                                                                                columns = @($SchemaSourceObject)
                                                                            }
                                                            }
                                            } | ConvertTo-Json -Depth 10

                    # create/update table schema using REST
                    $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($Table)?api-version=2021-12-01-preview"

                    Try
                        {
                            Write-Verbose ""
                            Write-Verbose "Trying to update existing LogAnalytics table schema for table [ $($Table) ] in "
                            Write-Verbose $AzLogWorkspaceResourceId

                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                        }
                    Catch
                        {

                            Write-Verbose ""
                            Write-Verbose "Internal error 500 - recreating table"
                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method DELETE -Headers $Headers
                                
                            Start-Sleep -Seconds 10
                            
                            # Changed to create with merged structure    
                            # invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPutFull
                            
                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                        }
                }
        }
        
    return
}

