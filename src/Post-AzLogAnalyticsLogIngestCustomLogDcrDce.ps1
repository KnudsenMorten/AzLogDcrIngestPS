Function Post-AzLogAnalyticsLogIngestCustomLogDcrDce
{
 <#
    .SYNOPSIS
    Send data to LogAnalytics using Log Ingestion API and Data Collection Rule

    .DESCRIPTION
    Data is either sent as one record (if only one exist), batches (calculated value of number of records to send per batch)
    - or BatchAmount (used only if the size of the records changes so you run into problems with limitations. 
    In case of diffent sizes, use 1 for BatchAmount
    Sending data in UTF8 format

    .VERSION
    1.0

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER DceUri
    Here you can put in the DCE uri - typically found using Get-DceDcrDetails

    .PARAMETER DcrImmutableId
    Here you can put in the DCR ImmunetableId - typically found using Get-DceDcrDetails

    .PARAMETER DcrStream
    Here you can put in the DCR Stream name - typically found using Get-DceDcrDetails

    .PARAMETER Data
    This is the data array

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
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $TableName                                       = 'InvClientComputerOSInfoV2'   # must not contain _CL
    $DcrName                                         = "dcr-" + $AzDcrPrefixClient + "-" + $TableName + "_CL"

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


    # build schema to be used for LogAnalytics Table
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType Table -Verbose:$Verbose

    CreateUpdate-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaSourceObject $Schema -TableName $TableName `
                                                    -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose 

    # build schema to be used for DCR
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType DCR

    CreateUpdate-AzDataCollectionRuleLogIngestCustomLog -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaSourceObject $Schema `
                                                        -DceName $DceName -DcrName $DcrName -TableName $TableName `
                                                        -LogIngestServicePricipleObjectId  $AzDcrLogIngestServicePrincipalObjectId `
                                                        -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    # here we post the data
    $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName -DceName $DceName `
                                            -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

    Post-AzLogAnalyticsLogIngestCustomLogDcrDce  -DceUri $AzDcrDceDetails[2] -DcrImmutableId $AzDcrDceDetails[6] -TableName $TableName `
                                                    -DcrStream $AzDcrDceDetails[7] -Data $DataVariable -BatchAmount $BatchAmount `
                                                    -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1317-byte response of content type application/json; charset=utf-8

      [ 1 / 1 ] - Posting data to Loganalytics table [ InvClientComputerOSInfoTESTV2_CL ] .... Please Wait !
    VERBOSE: POST with -1-byte payload
    VERBOSE: received -1-byte response of content type 
      SUCCESS - data uploaded to LogAnalytics
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DceURI,
            [Parameter(mandatory)]
                [AllowEmptyString()]
                [string]$DcrImmutableId,
            [Parameter(mandatory)]
                [AllowEmptyString()]
                [string]$DcrStream,
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter()]
                [string]$BatchAmount,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

    #--------------------------------------------------------------------------
    # Data check
    #--------------------------------------------------------------------------
    
    # On a newly created DCR, sometimes we cannot retrieve the DCR info fast enough. So we skip trying to send in data !
    If ( ($DcrImmutableId -eq $null) -or ($DcrStream -eq $null) )
        {
            # skipping as this is a newly created DCR. Just rerun the script and it will work !
        }
    Else
        {
            If ($DceURI -and $DcrImmutableId -and $DcrStream -and $Data)
                {
                    # Add assembly to upload using http
                    Add-Type -AssemblyName System.Web

                    #--------------------------------------------------------------------------
                    # Obtain a bearer token used to authenticate against the data collection endpoint using Azure App & Secret
                    #--------------------------------------------------------------------------

                        $scope       = [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
                        $bodytoken   = "client_id=$AzAppId&scope=$scope&client_secret=$AzAppSecret&grant_type=client_credentials";
                        $headers     = @{"Content-Type"="application/x-www-form-urlencoded"};
                        $uri         = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

                        $bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $bodytoken -Headers $headers).access_token

                        $headers = @{
                                        "Authorization" = "Bearer $bearerToken";
                                        "Content-Type" = "application/json";
                                    }


                    #--------------------------------------------------------------------------
                    # Upload the data using Log Ingesion API using DCE/DCR
                    #--------------------------------------------------------------------------
                    
                        # initial variable
                        $indexLoopFrom = 0

                        # calculate size of data (entries)
                        $TotalDataLines = ($Data | Measure-Object).count

                        # calculate number of entries to send during each transfer - log ingestion api limits to max 1 mb per transfer
                        If ( ($TotalDataLines -gt 1) -and ($BatchAmount -eq $null) )
                            {
                                $SizeDataSingleEntryJson  = (ConvertTo-Json -Depth 100 -InputObject @($Data[0]) -Compress).length
                                $DataSendAmountDecimal    = (( 1mb - 300Kb) / $SizeDataSingleEntryJson)   # 500 Kb is overhead (my experience !)
                                $DataSendAmount           = [math]::Floor($DataSendAmountDecimal)
                            }
                        ElseIf ($BatchAmount)
                            {
                                $DataSendAmount           = $BatchAmount
                            }
                        Else
                            {
                                $DataSendAmount           = 1
                            }

                        # loop - upload data in batches, depending on possible size & Azure limits 
                        Do
                            {
                                $DataSendRemaining = $TotalDataLines - $indexLoopFrom

                                If ($DataSendRemaining -le $DataSendAmount)
                                    {
                                        # send last batch - or whole batch
                                        $indexLoopTo    = $TotalDataLines - 1   # cause we start at 0 (zero) as first record
                                        $DataScopedSize = $Data   # no need to split up in batches
                                    }
                                ElseIf ($DataSendRemaining -gt $DataSendAmount)
                                    {
                                        # data must be splitted in batches
                                        $indexLoopTo    = $indexLoopFrom + $DataSendAmount
                                        $DataScopedSize = $Data[$indexLoopFrom..$indexLoopTo]
                                    }

                                # Convert data into JSON-format
                                $JSON = ConvertTo-Json -Depth 100 -InputObject @($DataScopedSize) -Compress

                                If ($DataSendRemaining -gt 1)    # batch
                                    {
                                        write-Output ""
                                    
                                        # we are showing as first record is 1, but actually is is in record 0 - but we change it for gui purpose
                                        Write-Output "  [ $($indexLoopFrom + 1)..$($indexLoopTo + 1) / $($TotalDataLines) ] - Posting data to Loganalytics table [ $($TableName)_CL ] .... Please Wait !"
                                    }
                                ElseIf ($DataSendRemaining -eq 1)   # single record
                                    {
                                        write-Output ""
                                        Write-Output "  [ $($indexLoopFrom + 1) / $($TotalDataLines) ] - Posting data to Loganalytics table [ $($TableName)_CL ] .... Please Wait !"
                                    }

                                $uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/$DcrStream"+"?api-version=2021-11-01-preview"
                            
                                # set encoding to UTF8
                                $JSON = [System.Text.Encoding]::UTF8.GetBytes($JSON)

                                $Result = Invoke-WebRequest -Uri $uri -Method POST -Body $JSON -Headers $headers -ErrorAction SilentlyContinue
                                $StatusCode = $Result.StatusCode

                                If ($StatusCode -eq "204")
                                    {
                                        Write-host "  SUCCESS - data uploaded to LogAnalytics"
                                    }
                                ElseIf ($StatusCode -eq "RequestEntityTooLarge")
                                    {
                                        Write-Error "  Error 513 - You are sending too large data - make the dataset smaller"
                                    }
                                Else
                                    {
                                        Write-Error $result
                                    }

                                # Set new Fom number, based on last record sent
                                $indexLoopFrom = $indexLoopTo

                            }
                        Until ($IndexLoopTo -ge ($TotalDataLines - 1 ))
              # return $result
        }
            
            Write-host ""
        }
}
