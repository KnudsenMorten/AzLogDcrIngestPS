Function Get-AzLogAnalyticsTableAzDataCollectionRuleStatus
{
 <#
    .SYNOPSIS
    Get status about Azure Loganalytics tables and Data Collection Rule.

    .DESCRIPTION
    Used to detect if table/DCR must be create/updated - or it is valid to send in data

    .VERSION
    1.0

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER DcrName
    Specifies the DCR name

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER SchemaSourceObject
    This is the schema in hash table format coming from the source object

    .PARAMETER AzLogWorkspaceResourceId
    This is the Loganaytics Resource Id

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .PARAMETER Data
    This is the data array

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
	TRUE means existing environment must be updated - or table/DCR must be created
	FALSE means everything is ok including schema - next step is to post data
	
    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
    $verbose                                         = $true
    $TableName                                       = 'InvClientComputerOSInfoV2'   # must not contain _CL
    $DcrName                                         = "dcr-" + $AzDcrPrefixClient + "-" + $TableName + "_CL"

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $DceName                                         = "dce-log-platform-management-client-demo1-p" 
    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 
    $AzDcrPrefixClient                               = "clt1" 

    $TableName                                       = 'InvClientComputerOSInfoV2'   # must not contain _CL
    $DcrName                                         = "dcr-" + $AzDcrPrefixClient + "-" + $TableName + "_CL"

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

    $Schema = Get-ObjectSchemaAsArray -Data $DataVariable
    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    $StructureCheck

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Converting CIM array to Object & removing CIM class data in array .... please wait !
    VERBOSE:   Adding CollectionTime to all entries in array .... please wait !
    VERBOSE:   Validating schema structure of source data ... Please Wait !
    VERBOSE:   SUCCESS - No issues found in schema structure
    VERBOSE:   Aligning source object structure with schema ... Please Wait !
    VERBOSE:   Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 7749-byte response of content type application/json; charset=utf-8
    VERBOSE:   Success - Schema & DCR structure is OK
    $False
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter(mandatory)]
                [string]$DcrName,
            [Parameter(mandatory)]
                [array]$SchemaSourceObject,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )


    Write-Verbose "  Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !"

    # by default ($false)
    $AzDcrDceTableCustomLogCreateUpdate = $false     # $True/$False - typically used when updates to schema detected

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

        #--------------------------------------------------------------------------
        # Check if Azure LogAnalytics Table exist
        #--------------------------------------------------------------------------

            $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($TableName)_CL?api-version=2021-12-01-preview"
            $TableStatus = Try
                                {
                                    Invoke-RestMethod -Uri $TableUrl -Method GET -Headers $Headers
                                }
                           Catch
                                {
                                    Write-Verbose "  LogAnalytics table wasn't found !"
                                    # initial setup - force to auto-create structure
                                    $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                                }

        #--------------------------------------------------------------------------
        # Compare schema between source object schema and Azure LogAnalytics Table
        #--------------------------------------------------------------------------

            If ($TableStatus)
                {
                    $CurrentTableSchema = $TableStatus.properties.schema.columns

                    # Checking number of objects in schema
                        $CurrentTableSchemaCount = $CurrentTableSchema.count
                        $SchemaSourceObjectCount = ($SchemaSourceObject.count) + 1  # add 1 because TimeGenerated will automatically be added

                        If ($SchemaSourceObjectCount -gt $CurrentTableSchemaCount)
                            {
                               Write-Verbose "  Schema mismatch - Schema source object contains more properties than defined in current schema"
                               $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                            }

                    # Verify LogAnalytics table schema matches source object ($SchemaSourceObject) - otherwise set flag to update schema in LA/DCR
<#
                        ForEach ($Entry in $SchemaSourceObject)
                            {
                                $ChkSchema = $CurrentTableSchema | Where-Object { ($_.name -eq $Entry.name) -and ($_.type -eq $Entry.type) }

                                If ($ChkSchema -eq $null)
                                    {
                                        Write-Verbose "  Schema mismatch - property missing or different type (name: $($Entry.name), type: $($Entry.type))"
                                        # Set flag to update schema
                                        $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                                    }
                            }
#>
                }

        #--------------------------------------------------------------------------
        # Check if Azure Data Collection Rule exist
        #--------------------------------------------------------------------------

            # Check in global variable
            $DcrInfo = $global:AzDcrDetails | Where-Object { $_.name -eq $DcrName }
                If (!($DcrInfo))
                    {
                        Write-Verbose "  DCR was not found [ $($DcrName) ]"
                        # initial setup - force to auto-create structure
                        $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                    }

            If ($AzDcrDceTableCustomLogCreateUpdate -eq $false)
                {
                    Write-Verbose "  Success - Schema & DCR structure is OK"
                }

        Return $AzDcrDceTableCustomLogCreateUpdate
}
