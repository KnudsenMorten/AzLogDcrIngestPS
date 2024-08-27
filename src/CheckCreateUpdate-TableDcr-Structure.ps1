Function CheckCreateUpdate-TableDcr-Structure
{
 <#
    .SYNOPSIS
    Create or Update Azure Data Collection Rule (DCR) used for log ingestion to Azure LogAnalytics using Log Ingestion API (combined)

    .DESCRIPTION
    Combined function which will combine 3 functions in one call:
    Get-AzLogAnalyticsTableAzDataCollectionRuleStatus
    CreateUpdate-AzLogAnalyticsCustomLogTableDcr
    CreateUpdate-AzDataCollectionRuleLogIngestCustomLog

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER Data
    Data object

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER SchemaSourceObject
    This is the schema in hash table format coming from the source object

    .PARAMETER SchemaMode
    SchemaMode = Merge (default)
    It will do a merge/union of new properties and existing schema properties. DCR will import schema from table

    SchemaMode = Overwrite
    It will overwrite existing schema in DCR/table � based on source object schema
    This parameter can be useful for separate overflow work

    .PARAMETER EnableUploadViaLogHub
    $false = send logs directly to Azure, $true = send via remote path (log-hub), where log-engine will process data and upload. Made for legacy OS with TLS 1.0/1.1, PSVersion < 5.1

    .PARAMETER AzLogWorkspaceResourceId
    This is the Loganaytics Resource Id

    .PARAMETER DceName
    This is name of the Data Collection Endpoint to use for the upload
    Function will automatically look check in a global variable ($global:AzDceDetails) - or do a query using Azure Resource Graph to find DCE with name
    Goal is to find the log ingestion Uri on the DCE

    Variable $global:AzDceDetails can be build before calling this cmdlet using this syntax
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose -Verbose:$Verbose
 
    .PARAMETER DcrName
    This is name of the Data Collection Rule to use for the upload
    Function will automatically look check in a global variable ($global:AzDcrDetails) - or do a query using Azure Resource Graph to find DCR with name
    Goal is to find the DCR immunetable id on the DCR

    .PARAMETER DcrResourceGroup
    This is name of the resource group, where Data Collection Rules will be stored

    Variable $global:AzDcrDetails can be build before calling this cmdlet using this syntax
    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose -Verbose:$Verbose

    .PARAMETER TableName
    This is tablename of the LogAnalytics table (and is also used in the DCR naming)

    .PARAMETER AzDcrSetLogIngestApiAppPermissionsDcrLevel
    Choose TRUE if you want to set Monitoring Publishing Contributor permissions on DCR level
    Choose FALSE if you would like to use inherited permissions from the resource group level (recommended)

    .PARAMETER LogIngestServicePricipleObjectId
    This is the object id of the Azure App service-principal
    NOTE: Not the object id of the Azure app, but Object Id of the service principal (!)

    .PARAMETER AzLogDcrTableCreateFromReferenceMachine
    Array with list of computers, where schema management can be done

    .PARAMETER AzLogDcrTableCreateFromAnyMachine
    True means schema changes can be made from any computer - FALSE means it can only happen from reference machine(s)

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

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
            
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

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
            
    Write-Output ""
    Write-Output "Collecting OS information"

    $DataVariable = Get-CimInstance -ClassName Win32_OperatingSystem

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

    # convert CIM array to PSCustomObject and remove CIM class information
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable
    
    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable

    # add Computer & UserLoggedOn info to existing array
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name UserLoggedOn -Column2Data $UserLoggedOn

    # Validating/fixing schema data structure of source data
    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable

    # Aligning data structure with schema (requirement for DCR)
    $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable

    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

    CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId  `
                                            -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId `
                                            -DceName $DceName -DcrName $DcrName -TableName $TableName -Data $DataVariable `
                                            -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                            -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                            -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                            -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    Collecting OS information
    VERBOSE:   Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1468-byte response of content type application/json; charset=utf-8
    VERBOSE: GET with 0-byte payload
    VERBOSE:   LogAnalytics table wasn't found !
    VERBOSE:   DCR was not found [ dcr-clt1-InvClientComputerOSInfoTest4V2_CL ]
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1468-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: Trying to update existing LogAnalytics table schema for table [ InvClientComputerOSInfoTest4V2_CL ] in 
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PATCH with -1-byte payload
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7764-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: LogAnalytics Table doesn't exist or problems detected .... creating table [ InvClientComputerOSInfoTest4V2_CL ] in
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7764-byte response of content type application/json; charset=utf-8


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
    RawContentLength  : 7764

    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1468-byte response of content type application/json; charset=utf-8
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1342-byte response of content type application/json; charset=utf-8
    VERBOSE: Found required DCE info using Azure Resource Graph
    VERBOSE: 
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 898-byte response of content type application/json; charset=utf-8
    VERBOSE: Found required LogAnalytics info
    VERBOSE: 
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 291-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: Creating/updating DCR [ dcr-clt1-InvClientComputerOSInfoTest4V2_CL ] with limited payload
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/micros
    oft.insights/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest4V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 2094-byte response of content type application/json; charset=utf-8
    StatusCode        : 200
    StatusDescription : OK
    Content           : {"properties":{"immutableId":"dcr-3433400ee8ca4570b606a9a21f2eea79","dataCollectionEndpointId":"/subscriptions/fce4f2
                        82-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client...
    RawContent        : HTTP/1.1 200 OK
                        Pragma: no-cache
                        Vary: Accept-Encoding
                        x-ms-ratelimit-remaining-subscription-resource-requests: 149
                        Request-Context: appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3
                        x-ms-correla...
    Forms             : {}
    Headers           : {[Pragma, no-cache], [Vary, Accept-Encoding], [x-ms-ratelimit-remaining-subscription-resource-requests, 149], [Reques
                        t-Context, appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3]...}
    Images            : {}
    InputFields       : {}
    Links             : {}
    ParsedHtml        : mshtml.HTMLDocumentClass
    RawContentLength  : 2094

    VERBOSE: 
    VERBOSE: Updating DCR [ dcr-clt1-InvClientComputerOSInfoTest4V2_CL ] with full schema
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/micros
    oft.insights/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest4V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4546-byte response of content type application/json; charset=utf-8
    StatusCode        : 200
    StatusDescription : OK
    Content           : {"properties":{"immutableId":"dcr-3433400ee8ca4570b606a9a21f2eea79","dataCollectionEndpointId":"/subscriptions/fce4f2
                        82-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client...
    RawContent        : HTTP/1.1 200 OK
                        Pragma: no-cache
                        Vary: Accept-Encoding
                        x-ms-ratelimit-remaining-subscription-resource-requests: 148
                        Request-Context: appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3
                        x-ms-correla...
    Forms             : {}
    Headers           : {[Pragma, no-cache], [Vary, Accept-Encoding], [x-ms-ratelimit-remaining-subscription-resource-requests, 148], [Reques
                        t-Context, appId=cid-v1:2bbfbac8-e1b0-44af-b9c6-3a40669d37e3]...}
    Images            : {}
    InputFields       : {}
    Links             : {}
    ParsedHtml        : mshtml.HTMLDocumentClass
    RawContentLength  : 4546

    VERBOSE: 
    VERBOSE: Waiting 10 sec to let Azure sync up so DCR rule can be retrieved from Azure Resource Graph
    VERBOSE: 
    VERBOSE: Getting Data Collection Rules from Azure Resource Graph .... Please Wait !
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1468-byte response of content type application/json; charset=utf-8
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 104224-byte response of content type application/json; charset=utf-8

  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter(mandatory)]
                [string]$DcrName,
            [Parameter(mandatory)]
                [string]$DcrResourceGroup,
            [Parameter(mandatory)]
                [string]$DceName,
            [Parameter()]
                [AllowEmptyCollection()]
                [string]$LogIngestServicePricipleObjectId,
            [Parameter(mandatory)]
                [boolean]$AzDcrSetLogIngestApiAppPermissionsDcrLevel = $false,
            [Parameter()]
                [boolean]$AzLogDcrTableCreateFromAnyMachine,
            [Parameter()]
                [string]$SchemaMode = "Merge",     # Merge = Merge new properties into existing schema, Overwrite = use source object schema
            [Parameter()]
                [boolean]$EnableUploadViaLogHub = $false,
            [Parameter(mandatory)]
                [AllowEmptyCollection()]
                [array]$AzLogDcrTableCreateFromReferenceMachine,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )


    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------
        # default
        $IssuesFound = $false

        # Check for prohibited table names
        If ($TableName -like "_*")   # remove any leading underscores - column in DCR/LA must start with a character
            {
                $IssuesFound = $true
                Write-Verbose ""
                Write-Verbose "  ISSUE - Table name must start with character [ $($TableName) ]"
                Write-Verbose ""
            }
        ElseIf ($TableName -like "*-*")   # includes - (hyphen)
            {
                $IssuesFound = $true
                Write-Verbose ""
                Write-Verbose "  ISSUE - Table name include - (hyphen) - must be removed [ $($TableName) ]"
                Write-Verbose ""
            }
        ElseIf ($TableName -like "*:*")   # includes : (semicolon)
            {
                $IssuesFound = $true
                Write-Verbose ""
                Write-Verbose "  ISSUE - Table name include : (semicolon) - must be removed [ $($TableName) ]"
                Write-Verbose ""
            }
        ElseIf ($TableName -like "*.*")   # includes . (period)
            {
                $IssuesFound = $true
                Write-Verbose ""
                Write-Verbose "  ISSUE - Table name include . (period) - must be removed [ $($TableName) ]"
                Write-Verbose ""
            }
        ElseIf ($TableName -like "* *")   # includes whitespace " "
            {
                $IssuesFound = $true
                Write-Verbose ""
                Write-Verbose "  ISSUE - Table name include whitespace - must be removed [ $($TableName) ]"
                Write-Verbose ""
            }

        If ( ($EnableUploadViaLogHub -eq $false) -and ($IssuesFound -eq $false) )
            {
                If ( ($AzAppId) -and ($AzAppSecret) )
                    {
                        #-----------------------------------------------------------------------------------------------
                        # Check if table and DCR exist - or schema must be updated due to source object schema changes
                        #-----------------------------------------------------------------------------------------------
                    
                            # Get insight about the schema structure
                            $Schema = Get-ObjectSchemaAsArray -Data $Data
                            $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                                                -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

                        #-----------------------------------------------------------------------------------------------
                        # Structure check = $true -> Create/update table & DCR with necessary schema
                        #-----------------------------------------------------------------------------------------------

                            If ($StructureCheck -eq $true)
                                {
                                    If ( ( $env:COMPUTERNAME -in $AzLogDcrTableCreateFromReferenceMachine) -or ($AzLogDcrTableCreateFromAnyMachine -eq $true) )    # manage table creations
                                        {
                                    
                                            # build schema to be used for LogAnalytics Table
                                            $Schema = Get-ObjectSchemaAsHash -Data $Data -ReturnType Table -Verbose:$Verbose

                                            $ResultLA = CreateUpdate-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -SchemaSourceObject $Schema -TableName $TableName `
                                                                                                     -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose -SchemaMode $SchemaMode


                                            # build schema to be used for DCR
                                            $Schema = Get-ObjectSchemaAsHash -Data $Data -ReturnType DCR

                                            $ResultDCR = CreateUpdate-AzDataCollectionRuleLogIngestCustomLog -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -SchemaSourceObject $Schema `
                                                                                                             -DceName $DceName -DcrName $DcrName -DcrResourceGroup $DcrResourceGroup -TableName $TableName `
                                                                                                             -LogIngestServicePricipleObjectId $LogIngestServicePricipleObjectId -SchemaMode $SchemaMode `
                                                                                                             -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                                                                             -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

                                            Return $ResultLA, $ResultDCR
                                        }
                                }
                        } # create table/DCR
            }
}

# SIG # Begin signature block
# MIIXAgYJKoZIhvcNAQcCoIIW8zCCFu8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUowENFvmj0OK9nzuPb5wKKMVV
# 1DSgghNiMIIFojCCBIqgAwIBAgIQeAMYQkVwikHPbwG47rSpVDANBgkqhkiG9w0B
# AQwFADBMMSAwHgYDVQQLExdHbG9iYWxTaWduIFJvb3QgQ0EgLSBSMzETMBEGA1UE
# ChMKR2xvYmFsU2lnbjETMBEGA1UEAxMKR2xvYmFsU2lnbjAeFw0yMDA3MjgwMDAw
# MDBaFw0yOTAzMTgwMDAwMDBaMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9i
# YWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2lnbmluZyBS
# b290IFI0NTCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALYtxTDdeuir
# kD0DcrA6S5kWYbLl/6VnHTcc5X7sk4OqhPWjQ5uYRYq4Y1ddmwCIBCXp+GiSS4LY
# S8lKA/Oof2qPimEnvaFE0P31PyLCo0+RjbMFsiiCkV37WYgFC5cGwpj4LKczJO5Q
# OkHM8KCwex1N0qhYOJbp3/kbkbuLECzSx0Mdogl0oYCve+YzCgxZa4689Ktal3t/
# rlX7hPCA/oRM1+K6vcR1oW+9YRB0RLKYB+J0q/9o3GwmPukf5eAEh60w0wyNA3xV
# uBZwXCR4ICXrZ2eIq7pONJhrcBHeOMrUvqHAnOHfHgIB2DvhZ0OEts/8dLcvhKO/
# ugk3PWdssUVcGWGrQYP1rB3rdw1GR3POv72Vle2dK4gQ/vpY6KdX4bPPqFrpByWb
# EsSegHI9k9yMlN87ROYmgPzSwwPwjAzSRdYu54+YnuYE7kJuZ35CFnFi5wT5YMZk
# obacgSFOK8ZtaJSGxpl0c2cxepHy1Ix5bnymu35Gb03FhRIrz5oiRAiohTfOB2FX
# BhcSJMDEMXOhmDVXR34QOkXZLaRRkJipoAc3xGUaqhxrFnf3p5fsPxkwmW8x++pA
# sufSxPrJ0PBQdnRZ+o1tFzK++Ol+A/Tnh3Wa1EqRLIUDEwIrQoDyiWo2z8hMoM6e
# +MuNrRan097VmxinxpI68YJj8S4OJGTfAgMBAAGjggF3MIIBczAOBgNVHQ8BAf8E
# BAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMwDwYDVR0TAQH/BAUwAwEB/zAdBgNV
# HQ4EFgQUHwC/RoAK/Hg5t6W0Q9lWULvOljswHwYDVR0jBBgwFoAUj/BLf6guRSSu
# TVD6Y5qL3uLdG7wwegYIKwYBBQUHAQEEbjBsMC0GCCsGAQUFBzABhiFodHRwOi8v
# b2NzcC5nbG9iYWxzaWduLmNvbS9yb290cjMwOwYIKwYBBQUHMAKGL2h0dHA6Ly9z
# ZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L3Jvb3QtcjMuY3J0MDYGA1UdHwQv
# MC0wK6ApoCeGJWh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vcm9vdC1yMy5jcmww
# RwYDVR0gBEAwPjA8BgRVHSAAMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmds
# b2JhbHNpZ24uY29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBDAUAA4IBAQCs98wV
# izB5qB0LKIgZCdccf/6GvXtaM24NZw57YtnhGFywvRNdHSOuOVB2N6pE/V8BI1mG
# VkzMrbxkExQwpCCo4D/onHLcfvPYDCO6qC2qPPbsn4cxB2X1OadRgnXh8i+X9tHh
# ZZaDZP6hHVH7tSSb9dJ3abyFLFz6WHfRrqexC+LWd7uptDRKqW899PMNlV3m+XpF
# sCUXMS7b9w9o5oMfqffl1J2YjNNhSy/DKH563pMOtH2gCm2SxLRmP32nWO6s9+zD
# CAGrOPwKHKnFl7KIyAkCGfZcmhrxTWww1LMGqwBgSA14q88XrZKTYiB3dWy9yDK0
# 3E3r2d/BkJYpvcF/MIIGvzCCBKegAwIBAgIRAIFOQhehKX/tWszUF/iRrXUwDQYJ
# KoZIhvcNAQELBQAwUzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24g
# bnYtc2ExKTAnBgNVBAMTIEdsb2JhbFNpZ24gQ29kZSBTaWduaW5nIFJvb3QgUjQ1
# MB4XDTI0MDYxOTAzMjUxMVoXDTM4MDcyODAwMDAwMFowWTELMAkGA1UEBhMCQkUx
# GTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExLzAtBgNVBAMTJkdsb2JhbFNpZ24g
# R0NDIFI0NSBDb2RlU2lnbmluZyBDQSAyMDIwMIICIjANBgkqhkiG9w0BAQEFAAOC
# Ag8AMIICCgKCAgEA1kJN+eNPxiP0bB2BpjD3SD3P0OWN5SAilgdENV0Gzw8dcGDm
# JlT6UyNgAqhfAgL3jsluPal4Bb2O9U8ZJJl8zxEWmx97a9Kje2hld6vYsSw/03IG
# MlxbrFBnLCVNVgY2/MFiTH19hhaVml1UulDQsH+iRBnp1m5sPhPCnxHUXzRbUWgx
# Ywr4W9DeullfMa+JaDhAPgjoU2dOY7Yhju/djYVBVZ4cvDfclaDEcacfG6VJbgog
# WX6Jo1gVlwAlad/ewmpQZU5T+2uhnxgeig5fVF694FvP8gwE0t4IoRAm97Lzei7C
# jpbBP86l2vRZKIw3ZaExlguOpHZ3FUmEZoIl50MKd1KxmVFC/6Gy3ZzS3BjZwYap
# QB1Bl2KGvKj/osdjFwb9Zno2lAEgiXgfkPR7qVJOak9UBiqAr57HUEL6ZQrjAfSx
# bqwOqOOBGag4yJ4DKIakdKdHlX5yWip7FWocxGnmsL5AGZnL0n1VTiKcEOChW8Oz
# LnqLxN7xSx+MKHkwRX9sE7Y9LP8tSooq7CgPLcrUnJiKSm1aNiwv37rL4kFKCHcY
# iK01YZQS86Ry6+42nqdRJ5E896IazPyH5ZfhUYdp6SLMg8C3D0VsB+FDT9SMSs7P
# Y7G1pBB6+Q0MKLBrNP4haCdv7Pj6JoRbdULNiSZ5WZ1rq2NxYpAlDQgg8f8CAwEA
# AaOCAYYwggGCMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAKBggrBgEFBQcDAzAS
# BgNVHRMBAf8ECDAGAQH/AgEAMB0GA1UdDgQWBBTas43AJJCja3fTDKBZ3SFnZHYL
# eDAfBgNVHSMEGDAWgBQfAL9GgAr8eDm3pbRD2VZQu86WOzCBkwYIKwYBBQUHAQEE
# gYYwgYMwOQYIKwYBBQUHMAGGLWh0dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2Nv
# ZGVzaWduaW5ncm9vdHI0NTBGBggrBgEFBQcwAoY6aHR0cDovL3NlY3VyZS5nbG9i
# YWxzaWduLmNvbS9jYWNlcnQvY29kZXNpZ25pbmdyb290cjQ1LmNydDBBBgNVHR8E
# OjA4MDagNKAyhjBodHRwOi8vY3JsLmdsb2JhbHNpZ24uY29tL2NvZGVzaWduaW5n
# cm9vdHI0NS5jcmwwLgYDVR0gBCcwJTAIBgZngQwBBAEwCwYJKwYBBAGgMgEyMAwG
# CisGAQQBoDIKBAIwDQYJKoZIhvcNAQELBQADggIBADIQ5LwXpYMQQJ3Tqf0nz0Vy
# qcUfSzNZbywyMXlxhNY2Z9WrdPzU8gY6brXWy/FCg5a9fd6VLBrtauNBHKbIiTHC
# WWyJvCojA1lQR0n9b1MOKijMSFTv8yMYW5I2TryjY9TD+wAPgNEgwsrllrrwmluq
# pCV6Gdv623tTT/m2o9lj1XVfAaUo27YYKRRleZzbtOuImBRTUGAxDGazUeNuySkm
# ZPAU0XN4xISNPhSlklmreUFG6jTPgXZGOpF4GXO+/gb118GEOaBwTAo1AF7YKjAk
# HzJ3tuF837NGQeH6bY3j4wufL0DZpToNZMm+jNEayWUgOuIA+k56ITdBcJmdUB+Z
# e3WQdHNNRaVOWH/ddmqQWIlmk2Sj/lT3Tarr5SDuddeIsh0MPLyhkqBW5Ef8Zw/q
# eCnfj6PH2eMxeKcLKZRrHCddISeH4qPvyECQLlwXKCXTAUQXq4DafJSoWyP8IJ6b
# kaGQ/7MN5XJELEcV89SRcib58gXjAWf3abXeBbb+KJCMf6EpO7cs2mQiaZbE9NNX
# DSqFxrtoaKyL8VJLZG6quLfsTRQc+qgUOM7sJevkYt01+bh7B10bQ2cCCGs9vyUj
# g4GWcwfu/lhaPDfaoNtf0pw6RpKcxCYcCTDaJeQOHZBz1B6HTmmEgZHNZX7nNfqD
# gGrTNB1Gp3gIpngyJWZ6MIIG9TCCBN2gAwIBAgIMeWPZY2rjO3HZBQJuMA0GCSqG
# SIb3DQEBCwUAMFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52
# LXNhMS8wLQYDVQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0Eg
# MjAyMDAeFw0yMzAzMjcxMDIxMzRaFw0yNjAzMjMxNjE4MThaMGMxCzAJBgNVBAYT
# AkRLMRAwDgYDVQQHEwdLb2xkaW5nMRAwDgYDVQQKEwcybGlua0lUMRAwDgYDVQQD
# EwcybGlua0lUMR4wHAYJKoZIhvcNAQkBFg9tb2tAMmxpbmtpdC5uZXQwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDMpI1rTOoWOSET3lSFQfsl/t83DCUE
# doI02fNS5xlURPeGZNhixQMKrhmFrdbIaEx01eY+hH9gF2AQ1ZDa7orCVSde1LDB
# nbFPLqcHWW5RWyzcy8PqgV1QvzlFbmvTNHLm+wn1DZJ/1qJ+A+4uNUMrg13WRTiH
# 0YWd6pwmAiQkoGC6FFwEusXotrT5JJNcPGlxBccm8su3kakI5B6iEuTeKh92EJM/
# km0pc/8o+pg+uR+f07PpWcV9sS//JYCSLaXWicfrWq6a7/7U/vp/Wtdz+d2Dcwlj
# psoXd++vuwzF8cUs09uJKtdyrN8Z1DxqFlMdlD0ZyR401qAX4GO2XdzH363TtEBK
# AwvV+ReW6IeqGp5FUjnUj0RZ7NPOSiPr5G7d23RutjCHlGzbUr+5mQV/IHGL9LM5
# aNHsu22ziVqImRU9nwfqQVb8Q4aWD9P92hb3jNcH4bIWiQYccf9hgrMGGARx+wd/
# vI+AU/DfEtN9KuLJ8rNkLfbXRSB70le5SMP8qK09VjNXK/i6qO+Hkfh4vfNnW9JO
# vKdgRnQjmNEIYWjasbn8GyvoFVq0GOexiF/9XFKwbdGpDLJYttfcVZlBoSMPOWRe
# 8HEKZYbJW1McjVIpWPnPd6tW7CBY2jp4476OeoPpMiiApuc7BhUC0VWl1Ei2PovD
# Uoh/H3euHrWqbQIDAQABo4IBsTCCAa0wDgYDVR0PAQH/BAQDAgeAMIGbBggrBgEF
# BQcBAQSBjjCBizBKBggrBgEFBQcwAoY+aHR0cDovL3NlY3VyZS5nbG9iYWxzaWdu
# LmNvbS9jYWNlcnQvZ3NnY2NyNDVjb2Rlc2lnbmNhMjAyMC5jcnQwPQYIKwYBBQUH
# MAGGMWh0dHA6Ly9vY3NwLmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25j
# YTIwMjAwVgYDVR0gBE8wTTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0
# cHM6Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkG
# A1UdEwQCMAAwRQYDVR0fBD4wPDA6oDigNoY0aHR0cDovL2NybC5nbG9iYWxzaWdu
# LmNvbS9nc2djY3I0NWNvZGVzaWduY2EyMDIwLmNybDATBgNVHSUEDDAKBggrBgEF
# BQcDAzAfBgNVHSMEGDAWgBTas43AJJCja3fTDKBZ3SFnZHYLeDAdBgNVHQ4EFgQU
# McaWNqucqymu1RTg02YU3zypsskwDQYJKoZIhvcNAQELBQADggIBAHt/DYGUeCFf
# btuuP5/44lpR2wbvOO49b6TenaL8TL3VEGe/NHh9yc3LxvH6PdbjtYgyGZLEooIg
# fnfEo+WL4fqF5X2BH34yEAsHCJVjXIjs1mGc5fajx14HU52iLiQOXEfOOk3qUC1T
# F3NWG+9mezho5XZkSMRo0Ypg7Js2Pk3U7teZReCJFI9FSYa/BT2DnRFWVTlx7T5l
# Iz6rKvTO1qQC2G3NKVGsHMtBTjsF6s2gpOzt7zF3o+DsnJukQRn0R9yTzgrx9nXY
# iHz6ti3HuJ4U7i7ILpgSRNrzmpVXXSH0wYxPT6TLm9eZR8qdZn1tGSb1zoIT70ar
# nzE90oz0x7ej1fC8IUA/AYhkmfa6feI7OMU5xnsUjhSiyzMVhD06+RD3t5JrbKRo
# CgqixGb7DGM+yZVjbmhwcvr3UGVld9++pbsFeCB3xk/tcMXtBPdHTESPvUjSCpFb
# yldxVLU6GVIdzaeHAiByS0NXrJVxcyCWusK41bJ1jP9zsnnaUCRERjWF5VZsXYBh
# Y62NSOlFiCNGNYmVt7fib4V6LFGoWvIv2EsWgx/uR/ypWndjmV6uBIN/UMZAhC25
# iZklNLFGDZ5dCUxLuoyWPVCTBYpM3+bN6dmbincjG0YDeRjTVfPN5niP1+SlRwSQ
# xtXqYoDHq+3xVzFWVBqCNdoiM/4DqJUBMYIDCjCCAwYCAQEwaTBZMQswCQYDVQQG
# EwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEvMC0GA1UEAxMmR2xvYmFs
# U2lnbiBHQ0MgUjQ1IENvZGVTaWduaW5nIENBIDIwMjACDHlj2WNq4ztx2QUCbjAJ
# BgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0B
# CQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAj
# BgkqhkiG9w0BCQQxFgQUn7kX47V7cD0cmF818/onD6mkFoMwDQYJKoZIhvcNAQEB
# BQAEggIAEcd5G6AD/d+vlX19W6WD2fMjvUvdxTlj7etd3AfgZ50uvD/M6A7Xa7th
# RWUyEhSQlV+HnslSGsEgTcdw+1g2Ibb3ChKoQR8Cyn0srf/KdAMFsMk+NAHc0pDA
# fe/KwxYYvP5xAMXsIbxKM3dfca+FkehYCZ7BA+My0fB69akaFlH8Nsbz58nQahuX
# NBOk+k2CHvnmMkbrrfs+ybaoLksKEXcgf+KjD6uhdwASI0KLa6HDqNYhGA2qXlFC
# zCKogl8EJ1QJp4I+KygB+iRHezUIwM36BbpP1Xhu/mbR/stiyfJ5YtXlo8URditr
# +7U806T22dFfQVj0EFxXMp8lsv7UDvEpCL7ksm8JoyhSpJmSEDu9y5RB1xUe/vB3
# Vre0S9Yl4RWoWZ4yZw+F7Tmt+T+Nc51b8vbxwxA/7dUquTRs8ZU012Hx3yFv1wL1
# jZk8r1s3C0rQXwdlg23u1Ejqx30joks/9WpxmCaARAgtGBX42xW24/UT+7VLcBQC
# JQ2XulqdYMFy58uv7WMbFLmolKMszO4CV7vEtaQguB2ddfDHErRKvumGu5/dXBj7
# UuRmUVuavtpFONOXH8ZVILN+vkk0xW3YftposwD+GrYrByy6Sw2lZrcQ/cq31nX4
# vvrVPP939zlbxXm4m7wzZEz0OHF9oju5FQWQROrurx8/UJTl5GI=
# SIG # End signature block
