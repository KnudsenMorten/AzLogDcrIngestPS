Function CreateUpdate-AzLogAnalyticsCustomLogTableDcr ($TableName, $SchemaSourceObject, $AzLogWorkspaceResourceId, $AzAppId, $AzAppSecret, $TenantId)
{

        <#  TESTING !!

            $AzLogWorkspaceResourceId = $global:MainLogAnalyticsWorkspaceResourceId
            $SchemaSourceObject       = $DataVariable[0]
            $TableName                = $TableName


            # ClientInspector
            $AzLogWorkspaceResourceId = $LogAnalyticsWorkspaceResourceId
            $SchemaSourceObject       = $Schema
            $TableName                = $TableName 
            $AzAppId                  = $LogIngestAppId
            $AzAppSecret              = $LogIngestAppSecret
            $TenantId                 = $TenantId
        #>

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # LogAnalytics Table check
    #--------------------------------------------------------------------------

        $Table         = $TableName  + "_CL"    # TableName with _CL (CustomLog)

        If ($Table.Length -gt 45)
            {
                write-host "ERROR - Reduce length of tablename, as it has a maximum of 45 characters (current length: $($Table.Length))"
                pause
            }

    #--------------------------------------------------------------------------
    # Creating/Updating LogAnalytics Table based upon data source schema
    #--------------------------------------------------------------------------

        $Changes = $SchemaSourceObject[40]

<#
        $tableBodyPatch = @{
                                properties = @{
                                                schema = @{
                                                                name    = $Table
                                                                columns = @($Changes)
                                                            }
                                            }
                           } | ConvertTo-Json -Depth 10
#>
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
                Write-Host ""
                Write-host "Trying to update existing LogAnalytics table schema for table [ $($Table) ] in "
                Write-host $AzLogWorkspaceResourceId

                Invoke-WebRequest -Uri $TableUrl -Method Patch -Headers $Headers -Body $TablebodyPut
            }
        Catch
            {
                Try
                    {
                        Write-Host ""
                        Write-Host "LogAnalytics Table doesn't exist or problems detected .... creating table [ $($Table) ] in"
                        Write-host $AzLogWorkspaceResourceId

                        Invoke-WebRequest -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                    }
                Catch
                    {
                        Write-Host ""
                        Write-Host "Something went wrong .... recreating table [ $($Table) ] in"
                        Write-host $AzLogWorkspaceResourceId

                        Invoke-WebRequest -Uri $TableUrl -Method DELETE -Headers $Headers
                                
                        Start-Sleep -Seconds 10
                                
                        Invoke-WebRequest -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                    }
            }
        
        return
}


Function CreateUpdate-AzDataCollectionRuleLogIngestCustomLog ($SchemaSourceObject, $AzLogWorkspaceResourceId, $DceName, $DcrName, $TableName, $TablePrefix, $AzDcrSetLogIngestApiAppPermissionsDcrLevel, `
                                                              $LogIngestServicePricipleObjectId, $AzAppId, $AzAppSecret, $TenantId)
{

<#   TROUBLESHOOTING

        # Function variables
        $AzLogWorkspaceResourceId                   = $global:MainLogAnalyticsWorkspaceResourceId
        
        # $DceName                                    = $Global:AzDceNameSrvNetworkCloud

        $SchemaSourceObject                         = $DataVariable[0]

        # $TablePrefix                                = $Global:AzDcrPrefixSrvNetworkCloud
        $TablePrefix                                = $AzDcrPrefixClient

        $LogIngestServicePricipleObjectId           = $Global:AzDcrLogIngestServicePrincipalObjectId
        $AzDcrSetLogIngestApiAppPermissionsDcrLevel = $Global:AzDcrSetLogIngestApiAppPermissionsDcrLevel
        $AzAppId                                    = $TableDcrSchemaCreateUpdateAppId
        $AzAppSecret                                = $TableDcrSchemaCreateUpdateAppSecret

      # ClientInspector testing
        $AzLogWorkspaceResourceId                   = $LogAnalyticsWorkspaceResourceId
        $SchemaSourceObject                         = $Schema
        $LogIngestServicePricipleObjectId           = $AzDcrLogIngestServicePrincipalObjectId
        $AzDcrSetLogIngestApiAppPermissionsDcrLevel = $AzDcrSetLogIngestApiAppPermissionsDcrLevel
        $TablePrefix                                = $AzDcrPrefixClient

        $AzAppId                                    = $LogIngestAppId
        $AzAppSecret                                = $LogIngestAppSecret
        # $DceName 
        # $TenantId
#>

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

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
                                    Write-Output "Could not find DCE with name [ $($DceName) ]"
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

        # DCE ResourceId (target for DCR ingestion)
        $DceResourceId  = $DceInfo.id
        If ($DceInfo)
            {
                Write-Verbose "Found required DCE info using Azure Resource Graph"
                Write-Verbose ""
            }

    #------------------------------------------------------------------------------------------------
    # Getting LogAnalytics Info
    #------------------------------------------------------------------------------------------------
                
        $LogWorkspaceUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "?api-version=2021-12-01-preview"
        $LogWorkspaceId = (Invoke-RestMethod -Uri $LogWorkspaceUrl -Method GET -Headers $Headers).properties.customerId
        If ($LogWorkspaceId)
            {
                Write-Verbose "Found required LogAnalytics info"
                Write-Verbose ""
            }
                
    #------------------------------------------------------------------------------------------------
    # Build variables
    #------------------------------------------------------------------------------------------------

        # build variables
        $KustoDefault                               = "source | extend TimeGenerated = now()"
        $StreamNameFull                             = "Custom-" + $TableName + "_CL"

        # streamname must be 52 characters or less
        If ($StreamNameFull.length -gt 52)
            {
                $StreamName                         = $StreamNameFull.Substring(0,52)
            }
        Else
            {
                $StreamName                         = $StreamNameFull
            }

        $DceLocation                                = $DceInfo.location

        # default naming convention, if not specificed
        If ($Dcrname -eq $null)
            {
                $DcrName                            = "dcr-" + $TablePrefix + "-" + $TableName + "_CL"
            }

        $DcrSubscription                            = ($AzLogWorkspaceResourceId -split "/")[2]
        $DcrLogWorkspaceName                        = ($AzLogWorkspaceResourceId -split "/")[-1]
        $DcrResourceGroup                           = "rg-dcr-" + $DcrLogWorkspaceName
        $DcrResourceId                              = "/subscriptions/$($DcrSubscription)/resourceGroups/$($DcrResourceGroup)/providers/microsoft.insights/dataCollectionRules/$($DcrName)"

    #--------------------------------------------------------------------------
    # Create resource group, if missing
    #--------------------------------------------------------------------------

        $Uri = "https://management.azure.com" + "/subscriptions/" + $DcrSubscription + "/resourcegroups/" + $DcrResourceGroup + "?api-version=2021-04-01"

        $CheckRG = Invoke-WebRequest -Uri $Uri -Method GET -Headers $Headers
        If ($CheckRG -eq $null)
            {
                $Body = @{
                            "location" = $DceLocation
                         } | ConvertTo-Json -Depth 5   

                Write-Host "Creating Resource group $($DcrResourceGroup) ... Please Wait !"
                $Uri = "https://management.azure.com" + "/subscriptions/" + $DcrSubscription + "/resourcegroups/" + $DcrResourceGroup + "?api-version=2021-04-01"
                $CreateRG = Invoke-WebRequest -Uri $Uri -Method PUT -Body $Body -Headers $Headers
            }

    #--------------------------------------------------------------------------
    # build initial payload to create DCR for log ingest (api) to custom logs
    #--------------------------------------------------------------------------

        If ($SchemaSourceObject.count -gt 10)
            {
                $SchemaSourceObjectLimited = $SchemaSourceObject[0..10]
            }
        Else
            {
                $SchemaSourceObjectLimited = $SchemaSourceObject
            }


        $DcrObject = [pscustomobject][ordered]@{
                        properties = @{
                                        dataCollectionEndpointId = $DceResourceId
                                        streamDeclarations = @{
                                                                $StreamName = @{
	  				                                                                columns = @(
                                                                                                $SchemaSourceObjectLimited
                                                                                               )
                                                                               }
                                                              }
                                        destinations = @{
                                                            logAnalytics = @(
                                                                                @{ 
                                                                                    workspaceResourceId = $AzLogWorkspaceResourceId
                                                                                    workspaceId = $LogWorkspaceId
                                                                                    name = $DcrLogWorkspaceName
                                                                                 }
                                                                            ) 

                                                        }
                                        dataFlows = @(
                                                        @{
                                                            streams = @(
                                                                            $StreamName
                                                                       )
                                                            destinations = @(
                                                                                $DcrLogWorkspaceName
                                                                            )
                                                            transformKql = $KustoDefault
                                                            outputStream = $StreamName
                                                         }
                                                     )
                                        }
                        location = $DceLocation
                        name = $DcrName
                        type = "Microsoft.Insights/dataCollectionRules"
                    }

    #--------------------------------------------------------------------------
    # create initial DCR using payload
    #--------------------------------------------------------------------------

        Write-Host ""
        Write-host "Creating/updating DCR [ $($DcrName) ] with limited payload"
        Write-host $DcrResourceId

        $DcrPayload = $DcrObject | ConvertTo-Json -Depth 20

        $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
        Invoke-WebRequest -Uri $Uri -Method PUT -Body $DcrPayload -Headers $Headers
        
        # sleeping to let API sync up before modifying
        Start-Sleep -s 5

    #--------------------------------------------------------------------------
    # build full payload to create DCR for log ingest (api) to custom logs
    #--------------------------------------------------------------------------

        $DcrObject = [pscustomobject][ordered]@{
                        properties = @{
                                        dataCollectionEndpointId = $DceResourceId
                                        streamDeclarations = @{
                                                                $StreamName = @{
	  				                                                                columns = @(
                                                                                                $SchemaSourceObject
                                                                                               )
                                                                               }
                                                              }
                                        destinations = @{
                                                            logAnalytics = @(
                                                                                @{ 
                                                                                    workspaceResourceId = $AzLogWorkspaceResourceId
                                                                                    workspaceId = $LogWorkspaceId
                                                                                    name = $DcrLogWorkspaceName
                                                                                 }
                                                                            ) 

                                                        }
                                        dataFlows = @(
                                                        @{
                                                            streams = @(
                                                                            $StreamName
                                                                       )
                                                            destinations = @(
                                                                                $DcrLogWorkspaceName
                                                                            )
                                                            transformKql = $KustoDefault
                                                            outputStream = $StreamName
                                                         }
                                                     )
                                        }
                        location = $DceLocation
                        name = $DcrName
                        type = "Microsoft.Insights/dataCollectionRules"
                    }

    #--------------------------------------------------------------------------
    # create DCR using payload
    #--------------------------------------------------------------------------

        Write-Host ""
        Write-host "Updating DCR [ $($DcrName) ] with full schema"
        Write-host $DcrResourceId

        $DcrPayload = $DcrObject | ConvertTo-Json -Depth 20

        $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
        Invoke-WebRequest -Uri $Uri -Method PUT -Body $DcrPayload -Headers $Headers

    #--------------------------------------------------------------------------
    # sleep 10 sec to let Azure Resource Graph pick up the new DCR
    #--------------------------------------------------------------------------

        Write-Host ""
        Write-host "Waiting 10 sec to let Azure sync up so DCR rule can be retrieved from Azure Resource Graph"
        Start-Sleep -Seconds 10

    #--------------------------------------------------------------------------
    # updating DCR list using Azure Resource Graph due to new DCR was created
    #--------------------------------------------------------------------------

        $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId

    #--------------------------------------------------------------------------
    # delegating Monitor Metrics Publisher Rolepermission to Log Ingest App
    #--------------------------------------------------------------------------

        If ($AzDcrSetLogIngestApiAppPermissionsDcrLevel -eq $true)
            {
                $DcrRule = $global:AzDcrDetails | where-Object { $_.name -eq $DcrName }
                $DcrRuleId = $DcrRule.id

                Write-Host ""
                Write-host "Setting Monitor Metrics Publisher Role permissions on DCR [ $($DcrName) ]"

                $guid = (new-guid).guid
                $monitorMetricsPublisherRoleId = "3913510d-42f4-4e42-8a64-420c390055eb"
                $roleDefinitionId = "/subscriptions/$($DcrSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($monitorMetricsPublisherRoleId)"
                $roleUrl = "https://management.azure.com" + $DcrRuleId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
                $roleBody = @{
                    properties = @{
                        roleDefinitionId = $roleDefinitionId
                        principalId      = $LogIngestServicePricipleObjectId
                        scope            = $DcrRuleId
                    }
                }
                $jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

                $result = try
                    {
                        Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                    }
                catch
                    {
                    }

                $StatusCode = $result.StatusCode
                If ($StatusCode -eq "204")
                    {
                        Write-host "  SUCCESS - data uploaded to LogAnalytics"
                    }
                ElseIf ($StatusCode -eq "RequestEntityTooLarge")
                    {
                        Write-Host "  Error 513 - You are sending too large data - make the dataset smaller"
                    }
                Else
                    {
                        Write-host $result
                    }

                # Sleep 10 sec to let Azure sync up
                Write-Host ""
                Write-host "Waiting 10 sec to let Azure sync up for permissions to replicate"
                Start-Sleep -Seconds 10
                Write-Host ""
            }

}

           
Function Update-AzDataCollectionRuleResetTransformKqlDefault ($DcrResourceId, $AzAppId, $AzAppSecret, $TenantId)
{
    #--------------------------------------------------------------------------
    # Variables
    #--------------------------------------------------------------------------

        $DefaultTransformKqlDcrLogIngestCustomLog = "source | extend TimeGenerated = now()"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($AzAppId)"
                                               client_secret = "$($AzAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method GET -Headers $Headers
        $DcrObj = $DCR.Content | ConvertFrom-Json

    #--------------------------------------------------------------------------
    # update payload object
    #--------------------------------------------------------------------------

        $DCRObj.properties.dataFlows[0].transformKql = $DefaultTransformKqlDcrLogIngestCustomLog

    #--------------------------------------------------------------------------
    # update existing DCR
    #--------------------------------------------------------------------------

        Write-host "  Resetting transformKql to default for DCR"
        Write-host $DcrResourceId

        # convert modified payload to JSON-format
        $DcrPayload = $DcrObj | ConvertTo-Json -Depth 20

        # update changes to existing DCR
        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers
}

Function Update-AzDataCollectionRuleTransformKql ($DcrResourceId, $transformKql, $AzAppId, $AzAppSecret, $TenantId)
{

<#

    $DcrResourceId = $DcrRuleId
    $transformKql  = $transformKql

#>
    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method GET -Headers $Headers

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
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers
}


Function Update-AzDataCollectionRuleLogAnalyticsCustomLogTableSchema ($SchemaSourceObject, $TableName, $DcrResourceId, $AzLogWorkspaceResourceId, $AzAppId, $AzAppSecret, $TenantId)
{

<#

    $SchemaSourceObject         = $DataVariable[0]
    $TableName                  = $CreateUpdateAzLACustomLogTable[0]
    $DcrResourceId              = $DcrResourceId
    $AzLogWorkspaceResourceId   = $global:MainLogAnalyticsWorkspaceResourceId

#>

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # build LogAnalytics Table schema based upon data source
    #--------------------------------------------------------------------------

        $Table         = $TableName  + "_CL"    # TableName with _CL (CustomLog)

        # Build initial hash used for columns for table schema
        $TableSchemaHash = @()

        # Requirement - Add TimeGenerated to array
        $TableSchemaObjHash = @{
                                    name        = "TimeGenerated"
                                    type        = "datetime"
                                    description = ""
                               }
        $TableSchemaHash    += $TableSchemaObjHash

        # Loop source object and build hash for table schema
        $ObjColumns = $SchemaSourceObject[0] | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Get-Member -MemberType NoteProperty
        ForEach ($Column in $ObjColumns)
            {
                $ObjDefinitionStr = $Column.Definition
                        If ($ObjDefinitionStr -like "int*")                                            { $ObjType = "int" }
                    ElseIf ($ObjDefinitionStr -like "real*")                                           { $ObjType = "int" }
                    ElseIf ($ObjDefinitionStr -like "long*")                                           { $ObjType = "long" }
                    ElseIf ($ObjDefinitionStr -like "guid*")                                           { $ObjType = "dynamic" }
                    ElseIf ($ObjDefinitionStr -like "string*")                                         { $ObjType = "string" }
                    ElseIf ($ObjDefinitionStr -like "datetime*")                                       { $ObjType = "datetime" }
                    ElseIf ($ObjDefinitionStr -like "bool*")                                           { $ObjType = "boolean" }
                    ElseIf ($ObjDefinitionStr -like "object*")                                         { $ObjType = "dynamic" }
                    ElseIf ($ObjDefinitionStr -like "System.Management.Automation.PSCustomObject*")    { $ObjType = "dynamic" }

                $TableSchemaObjHash = @{
                                            name        = $Column.Name
                                            type        = $ObjType
                                            description = ""
                                        }
                $TableSchemaHash    += $TableSchemaObjHash
            }

        # build table schema
        $tableBody = @{
                            properties = @{
                                            schema = @{
                                                            name    = $Table
                                                            columns = $TableSchemaHash
                                                        }
                                        }
                      } | ConvertTo-Json -Depth 10


    #--------------------------------------------------------------------------
    # update existing LogAnalytics Table based upon data source schema
    #--------------------------------------------------------------------------

        Write-host "  Updating LogAnalytics table schema for table [ $($Table) ]"
        Write-host ""

        # create/update table schema using REST
        $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($Table)?api-version=2021-12-01-preview"
        Invoke-RestMethod -Uri $TableUrl -Method PUT -Headers $Headers -Body $Tablebody

    #--------------------------------------------------------------------------
    # build Dcr schema based upon data source
    #--------------------------------------------------------------------------

        $DcrObjColumns = $SchemaSourceObject[0] | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Get-Member -MemberType NoteProperty
        
        $TableSchemaObject = @()

        # Requirement - Add TimeGenerated to array
        $TableSchemaObj = @{
                                    name        = "TimeGenerated"
                                    type        = "datetime"
                               }
        $TableSchemaObject   += $TableSchemaObj

        
        ForEach ($Column in $DcrObjColumns)
            {
                $ObjDefinitionStr = $Column.Definition
                        If ($ObjDefinitionStr -like "int*")                                            { $ObjType = "int" }
                    ElseIf ($ObjDefinitionStr -like "real*")                                           { $ObjType = "int" }
                    ElseIf ($ObjDefinitionStr -like "long*")                                           { $ObjType = "long" }
                    ElseIf ($ObjDefinitionStr -like "guid*")                                           { $ObjType = "dynamic" }
                    ElseIf ($ObjDefinitionStr -like "string*")                                         { $ObjType = "string" }
                    ElseIf ($ObjDefinitionStr -like "datetime*")                                       { $ObjType = "datetime" }
                    ElseIf ($ObjDefinitionStr -like "bool*")                                           { $ObjType = "boolean" }
                    ElseIf ($ObjDefinitionStr -like "object*")                                         { $ObjType = "dynamic" }
                    ElseIf ($ObjDefinitionStr -like "System.Management.Automation.PSCustomObject*")    { $ObjType = "dynamic" }

                $TableSchemaObj = @{
                                        "name"         = $Column.Name
                                        "type"         = $ObjType
                                    }
                $TableSchemaObject    += $TableSchemaObj
            }

    #--------------------------------------------------------------------------
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method GET
        $DcrObj = $DCR.Content | ConvertFrom-Json

    #--------------------------------------------------------------------------
    # update schema declaration in Dcr payload object
    #--------------------------------------------------------------------------

        $StreamName = "Custom-" + $TableName + "_CL"
        $DcrObj.properties.streamDeclarations.$StreamName.columns = $TableSchemaObject

    #--------------------------------------------------------------------------
    # update existing DCR
    #--------------------------------------------------------------------------

        # convert modified payload to JSON-format
        $DcrPayload = $DcrObj | ConvertTo-Json -Depth 20

        Write-host "  Updating declaration schema [ $($StreamName) ] for DCR"
        Write-host $DcrResourceId

        # update changes to existing DCR
        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = Invoke-RestMethod -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers
}


Function Update-AzDataCollectionRuleDceEndpoint ($DcrResourceId, $DceResourceId, $AzAppId, $AzAppSecret, $TenantId)
{
    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

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

Function Delete-AzLogAnalyticsCustomLogTables ($TableNameLike, $AzLogWorkspaceResourceId, $AzAppId, $AzAppSecret, $TenantId)
{
    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }


    #--------------------------------------------------------------------------
    # Getting list of Azure LogAnalytics tables
    #--------------------------------------------------------------------------

        Write-host "Getting list of tables in "
        Write-host $AzLogWorkspaceResourceId

        # create/update table schema using REST
        $TableUrl   = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables?api-version=2021-12-01-preview"
        $TablesRaw  = Invoke-RestMethod -Uri $TableUrl -Method GET -Headers $Headers
        $Tables     = $TablesRaw.value


    #--------------------------------------------------------------------------
    # Building list of tables to delete
    #--------------------------------------------------------------------------

        # custom Logs only
        $TablesScope = $Tables | where-object { $_.properties.schema.tableType -eq "CustomLog" }
        $TablesScope = $TablesScope  | where-object { $_.properties.schema.name -like $TableNameLike }

    #--------------------------------------------------------------------------
    # Deleting tables
    #--------------------------------------------------------------------------

        If ($TablesScope)
            {
                Write-host "LogAnalytics Resource Id"
                Write-host $AzLogWorkspaceResourceId
                Write-host ""
                Write-host "Table deletions in scope:"
                $TablesScope.properties.schema.name

                $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Delete"
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel"
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                $heading = "Delete Azure Loganalytics tables"
                $message = "Do you want to continue with the deletion of the shown tables?"
                $Prompt = $host.ui.PromptForChoice($heading, $message, $options, 1)
                switch ($prompt) {
                                    0
                                        {
                                            ForEach ($TableInfo in $TablesScope)
                                                { 
                                                    $Table = $TableInfo.properties.schema.name
                                                    Write-host "Deleting LogAnalytics table [ $($Table) ] ... Please Wait !"

                                                    $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($Table)?api-version=2021-12-01-preview"
                                                    Invoke-RestMethod -Uri $TableUrl -Method DELETE -Headers $Headers
                                                }
                                        }
                                    1
                                        {
                                            Write-Host "No" -ForegroundColor Red
                                        }
                                }
            }
}


Function Delete-AzDataCollectionRules ($DcrNameLike, $AzAppId, $AzAppSecret, $TenantId)
{
    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # Getting list of Azure Data Collection Rules using ARG
    #--------------------------------------------------------------------------

        $DCR_Rules_All = @()
        $pageSize = 1000
        $iteration = 0
        $searchParams = @{
                            Query = "Resources `
                                    | where type =~ 'microsoft.insights/datacollectionrules' "
                            First = $pageSize
                            }

        $results = do {
            $iteration += 1
            $pageResults = Search-AzGraph -UseTenantScope @searchParams
            $searchParams.Skip += $pageResults.Count
            $DCR_Rules_All += $pageResults
        } while ($pageResults.Count -eq $pageSize)

    #--------------------------------------------------------------------------
    # Building list of DCRs to delete
    #--------------------------------------------------------------------------

        $DcrScope = $DCR_Rules_All | Where-Object { $_.name -like $DcrNameLike }

    #--------------------------------------------------------------------------
    # Deleting DCRs
    #--------------------------------------------------------------------------

        If ($DcrScope)
            {
                Write-host "Data Collection Rules deletions in scope:"
                $DcrScope.name

                $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Delete"
                $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel"
                $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
                $heading = "Delete Azure Data Collection Rules"
                $message = "Do you want to continue with the deletion of the shown data collection rules?"
                $Prompt = $host.ui.PromptForChoice($heading, $message, $options, 1)
                switch ($prompt) {
                                    0
                                        {
                                            ForEach ($DcrInfo in $DcrScope)
                                                { 
                                                    $DcrResourceId = $DcrInfo.id
                                                    Write-host "Deleting Data Collection Rules [ $($DcrInfo.name) ] ... Please Wait !"
                                                    Invoke-AzRestMethod -Path ("$DcrResourceId"+"?api-version=2022-06-01") -Method DELETE
                                                }
                                        }
                                    1
                                        {
                                            Write-Host "No" -ForegroundColor Red
                                        }
                                }
            }
}


Function Get-AzDcrDceDetails ($DceName, $DcrName, $AzAppId, $AzAppSecret, $TenantId)
{
    <#  TROUBLESHOOTING

        $DcrName  = "dcr-Clt-Demo2_Processes_CL"
        $DceName  = "dce-platform-management-client-p"
    #>

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

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
                                    
                                    Start-Sleep -s 10

                                    # building global variable with all DCEs, which can be viewed by Log Ingestion app
                                    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
    
                                    $DceInfo = $global:AzDceDetails | Where-Object { $_.name -eq $DceName }
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
                                    # record not found - rebuild list and try again
                                    
                                    Start-Sleep -s 10

                                    # building global variable with all DCEs, which can be viewed by Log Ingestion app
                                    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
    
                                    $DcrInfo = $global:AzDceDetails | Where-Object { $_.name -eq $DcrName }
                                       If (!($DcInfo))
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


Function Post-AzLogAnalyticsLogIngestCustomLogDcrDce ($DceURI, $DcrImmutableId, $DcrStream, $Data, $BatchAmount, $AzAppId, $AzAppSecret, $TenantId)
{

        <#  TROUBLESHOOTING

        $DceUri              = $AzLogAnalyticsCustomLogDetails[0]
        $DcrImmutableId      = $AzLogAnalyticsCustomLogDetails[1]
        $DcrStream           = $AzLogAnalyticsCustomLogDetails[2]
        $Data                = $DataVariable
        $AzAppId             = $Global:AzDcrLogIngestAppId
        $AzAppSecret         = $Global:AzDcrLogIngestAppSecret
        $TenantId            = $Global:TenantId

        # ClientInspector
        $DceUri              = $AzDcrDceDetails[2]
        $DcrImmutableId      = $AzDcrDceDetails[6]
        $DcrStream           = $AzDcrDceDetails[7]
        $Data                = $DataVariable
        $AzAppId             = $LogIngestAppId
        $AzAppSecret         = $LogIngestAppSecret
        $TenantId            = $TenantId
        
        #>

    #--------------------------------------------------------------------------
    # Data check
    #--------------------------------------------------------------------------
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

                            $Result = Invoke-WebRequest -Uri $uri -Method POST -Body $JSON -Headers $headers -ErrorAction SilentlyContinue
                            $StatusCode = $Result.StatusCode

                            If ($StatusCode -eq "204")
                                {
                                    Write-host "  SUCCESS - data uploaded to LogAnalytics"
                                }
                            ElseIf ($StatusCode -eq "RequestEntityTooLarge")
                                {
                                    Write-Host "  Error 513 - You are sending too large data - make the dataset smaller"
                                }
                            Else
                                {
                                    Write-host $result
                                }

                            # Set new Fom number, based on last record sent
                            $indexLoopFrom = $indexLoopTo

                        }
                    Until ($IndexLoopTo -ge ($TotalDataLines - 1 ))
            
              # return $result
        }
        Write-host ""
}


Function ValidateFix-AzLogAnalyticsTableSchemaColumnNames ($Data)
{
    <#  TROUBLESHOOTING
        
        $Data = $DataVariable

    #>


    $ProhibitedColumnNames = @("_ResourceId","id","_ResourceId","_SubscriptionId","TenantId","Type","UniqueId","Title")

    Write-host "  Validating schema structure of source data ... Please Wait !"

    #-----------------------------------------------------------------------    
    # Initial check
    $IssuesFound = $false

        # loop through data
        ForEach ($Entry in $Data)
            {
                $ObjColumns = $Entry | Get-Member -MemberType NoteProperty

                ForEach ($Column in $ObjColumns)
                    {
                        # get column name
                        $ColumnName = $Column.Name

                        If ($ColumnName -in $ProhibitedColumnNames)   # phohibited column names
                            {
                                $IssuesFound = $true
                                write-host "  ISSUE - Column name is prohibited [ $($ColumnName) ]"
                            }

                        ElseIf ($ColumnName -like "_*")   # remove any leading underscores - column in DCR/LA must start with a character
                            {
                                $IssuesFound = $true
                                write-host "  ISSUE - Column name must start with character [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "*.*")   # includes . (period)
                            {
                                $IssuesFound = $true
                                write-host "  ISSUE - Column name include . (period) - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "* *")   # includes whitespace " "
                            {
                                $IssuesFound = $true
                                write-host "  ISSUE - Column name include whitespace - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName.Length -gt 45)   # trim the length to maximum 45 characters
                            {
                                $IssuesFound = $true
                                write-host "  ISSUE - Column length is greater than 45 characters (trimming column name is neccessary)  [ $($ColumnName) ]"
                            }
                    }
            }

    If ($IssuesFound)
        {
            Write-host "  Issues found .... fixing schema structure of source data ... Please Wait !"

            $DataCount  = ($Data | Measure-Object).Count

            $DataVariableQA = @()

            $Data | ForEach-Object -Begin  {
                    $i = 0
            } -Process {

                    # get column names
                    $ObjColumns = $_ | Get-Member -MemberType NoteProperty

                    ForEach ($Column in $ObjColumns)
                        {
                            # get column name
                            $ColumnName = $Column.Name

                            If ($ColumnName -in $ProhibitedColumnNames)   # phohibited column names
                                {
                                    $UpdColumn  = $ColumnName + "_"
                                    $ColumnData = $_.$ColumnName
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            ElseIf ($ColumnName -like "*.*")   # remove any . (period)
                                {
                                    $UpdColumn = $ColumnName.Replace(".","")
                                    $ColumnData = $Entry.$Column
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            ElseIf ($ColumnName -like "_*")   # remove any leading underscores - column in DCR/LA must start with a character
                                {
                                    $UpdColumn = $ColumnName.TrimStart("_")
                                    $ColumnData = $Entry.$Column
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            ElseIf ($ColumnName -like "* *")   # remove any whitespaces
                                {
                                    $UpdColumn = $ColumnName.TrimStart()
                                    $ColumnData = $Entry.$Column
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            ElseIf ($ColumnName.Length -gt 45)   # trim the length to maximum 45 characters
                                {
                                    $UpdColumn = $ColumnName.Substring(0,45)
                                    $ColumnData = $_.$Column
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            Else    # write column name and data (OK)
                                {
                                    $ColumnData = $_.$ColumnName
                                    $_ | Add-Member -MemberType NoteProperty -Name $ColumnName -Value $ColumnData -Force
                                }
                        }
                    $DataVariableQA += $_

                    # Increment the $i counter variable which is used to create the progress bar.
                    $i = $i+1

                    # Determine the completion percentage
                    $Completed = ($i/$DataCount) * 100
                    Write-Progress -Activity "Validating/fixing schema structure of source object" -Status "Progress:" -PercentComplete $Completed
            } -End {
                $Data = $DataVariableQA
            }
        }
    Else
        {
            Write-host "  SUCCESS - No issues found in schema structure"
        }
    Return $Data
}


Function Build-DataArrayToAlignWithSchema ($Data)
{
    <#  TROUBLESHOOTING
        
        $Data = $DataVariable
    #>

    Write-host "  Aligning source object structure with schema ... Please Wait !"
    
    # Get schema
    $Schema = Get-ObjectSchema -Data $DataVariable -ReturnFormat Array

    $DataCount  = ($Data | Measure-Object).Count

    $DataVariableQA = @()

    $Data | ForEach-Object -Begin  {
            $i = 0
    } -Process {
                    # get column names
                  #  $ObjColumns = $_ | Get-Member -MemberType NoteProperty

                    # enum schema
                    ForEach ($Column in $Schema)
                        {
                            # get column name & data
                            $ColumnName = $Column.Name
                            $ColumnData = $_.$ColumnName

                            $_ | Add-Member -MemberType NoteProperty -Name $ColumnName -Value $ColumnData -Force
                        }
                    $DataVariableQA += $_

                    # Increment the $i counter variable which is used to create the progress bar.
                    $i = $i+1

                    # Determine the completion percentage
                    $Completed = ($i/$DataCount) * 100
                    Write-Progress -Activity "Aligning source object structure with schema" -Status "Progress:" -PercentComplete $Completed
            } -End {
                
                # return data from temporary array to original $Data
                $Data = $DataVariableQA
            }
        Return $Data
}



Function Get-AzDataCollectionRuleNamingConventionSrv ($TableName)
    {
        # variables to be used for upload of data using DCR/log ingest api
        $DcrName    = "dcr-" + $Global:AzDcrPrefixSrvNetworkCloud + "-" + $TableName + "_CL"
        $DceName    = $Global:AzDceNameSrvNetworkCloud
        Return $DcrName, $DceName
    }

Function Get-AzDataCollectionRuleNamingConventionClt ($TableName)
    {
        # variables to be used for upload of data using DCR/log ingest api
        $DcrName    = "dcr-" + $Global:AzDcrPrefixClient + "-" + $TableName + "_CL"
        $DceName    = $Global:AzDceNameClient
        Return $DcrName, $DceName
    }

Function Get-AzLogAnalyticsTableAzDataCollectionRuleStatus ($AzLogWorkspaceResourceId, $TableName, $DcrName, $SchemaSourceObject, $AzAppId, $AzAppSecret, $TenantId)
    {

<#  TROUBLESHOOTING

    # ClientInspector
    $AzLogWorkspaceResourceId             = $LogAnalyticsWorkspaceResourceId
    $TableName                            = $TableName
    $DcrName                              = $DcrName
    $SchemaSourceObject                   = $Schema
    $AzAppId                              = $LogIngestAppId
    $AzAppSecret                          = $LogIngestAppSecret
    $TenantId                             = $TenantId

#>

    Write-host "  Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !"

    # by default ($false)
    $AzDcrDceTableCustomLogCreateUpdate = $false     # $True/$False - typically used when updates to schema detected

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

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
                                    Write-host "  LogAnalytics table wasn't found !"
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
                               Write-host "  Schema mismatch - Schema source object contains more properties than defined in current schema"
                               $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                            }

                    # Verify LogAnalytics table schema matches source object ($SchemaSourceObject) - otherwise set flag to update schema in LA/DCR
<#
                        ForEach ($Entry in $SchemaSourceObject)
                            {
                                $ChkSchema = $CurrentTableSchema | Where-Object { ($_.name -eq $Entry.name) -and ($_.type -eq $Entry.type) }

                                If ($ChkSchema -eq $null)
                                    {
                                        Write-host "  Schema mismatch - property missing or different type (name: $($Entry.name), type: $($Entry.type))"
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
                        Write-host "  DCR was not found [ $($DcrName) ]"
                        # initial setup - force to auto-create structure
                        $AzDcrDceTableCustomLogCreateUpdate = $true     # $True/$False - typically used when updates to schema detected
                    }

            If ($AzDcrDceTableCustomLogCreateUpdate -eq $false)
                {
                    Write-host "  Success - Schema & DCR structure is OK"
                }

        Return $AzDcrDceTableCustomLogCreateUpdate
    }


Function Add-ColumnDataToAllEntriesInArray ($Column1Name, $Column1Data, $Column2Name, $Column2Data, $Column3Name, $Column3Data, $Data)
    {
        Write-host "  Adding columns to all entries in array .... please wait !"
        $IntermediateObj = @()
        ForEach ($Entry in $Data)
            {
                If ($Column1Name)
                    {
                        $Entry | Add-Member -MemberType NoteProperty -Name $Column1Name -Value $Column1Data -Force
                    }

                If ($Column2Name)
                    {
                        $Entry | Add-Member -MemberType NoteProperty -Name $Column2Name -Value $Column2Data -Force
                    }

                If ($Column3Name)
                    {
                        $Entry | Add-Member -MemberType NoteProperty -Name $Column3Name -Value $Column3Data -Force
                    }

                $IntermediateObj += $Entry
            }
        return $IntermediateObj
    }

Function Add-CollectionTimeToAllEntriesInArray ($Data)
    {
        [datetime]$CollectionTime = ( Get-date ([datetime]::Now.ToUniversalTime()) -format "yyyy-MM-ddTHH:mm:ssK" )

        Write-host "  Adding CollectionTime to all entries in array .... please wait !"
        $IntermediateObj = @()
        ForEach ($Entry in $Data)
            {
                $Entry | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $CollectionTime -Force

                $IntermediateObj += $Entry
            }
        return $IntermediateObj
    }


Function Convert-CimArrayToObjectFixStructure ($Data)
    {
        Write-host "  Converting CIM array to Object & removing CIM class data in array .... please wait !"

        # Convert from array to object
        $Object = $Data | ConvertTo-Json | ConvertFrom-Json 

        # remove CIM info columns from object
        $ObjectModified = $Object | Select-Object -Property * -ExcludeProperty CimClass, CimInstanceProperties, CimSystemProperties

        return $ObjectModified
    }

Function Convert-PSArrayToObjectFixStructure ($Data)
    {
        Write-host "  Converting PS array to Object & removing PS class data in array .... please wait !"

        # Convert from array to object
        $Object = $Data | ConvertTo-Json | ConvertFrom-Json 

        # remove CIM info columns from object
        $ObjectModified = $Object | Select-Object -Property * -ExcludeProperty PSPath, PSProvider, PSParentPath, PSDrive, PSChildName, PSSnapIn

        return $ObjectModified
    }


Function Collect_MDE_Data_Upload_LogAnalytics ($CustomTable, $CollectionType, $Url, $AzLogWorkspaceResourceId, $TablePrefix, $DceName)
    { 

        <#  TROUBLESHOOTING

            $CollectionType            = $CollectionType
            $Url                       = $Url
            $CustomTable               = $CustomTable
            $AzLogWorkspaceResourceId  = $global:MainLogAnalyticsWorkspaceResourceId
            $TablePrefix               = $Global:AzDcrPrefixSrvNetworkCloud
            $DceName                   = $Global:AzDceNameSrvNetworkCloud

        #>

        ##########################################
        # COLLECTION OF DATA
        ##########################################
            Write-Output ""
            Write-Output "Collecting $($CollectionType) .... Please Wait !"

            $ResponseAllRecords = @()
            while ($Url -ne $null)
                {
                    # Connect to MDE API
                    Write-Output ""
                    Write-Output "  Retrieving data-set from Microsoft Defender Security Center API ... Please Wait !"
                    Connect_MDE_API

                        try 
                            {
                                # todo: verify that the bearer token is still good -- hasn't expired yet -- if it has, then get a new token before making the request
                                $ResponseRaw = Invoke-WebRequest -Method 'Get' -Uri $Url -Headers $global:Headers
                                $ResponseAllRecords += $ResponseRaw.content
                                $ResponseRawJSON = ($ResponseRaw | ConvertFrom-Json)

                                if($ResponseRawJSON.'@odata.nextLink')
                                    {
                                        $Url = $ResponseRawJSON.'@odata.nextLink'
                                    } 
                                else 
                                    {
                                        $Url = $null
                                    }
  
                            }
                        catch 
                            {
                                Write-output ""
                                Write-Output "StatusCode: " $_.Exception.Response.StatusCode.value__
                                Write-Output "StatusDescription:" $_.Exception.Response.StatusDescription
                                Write-output ""
  
                                if($_.ErrorDetails.Message)
                                    {
                                        Write-Output ""
                                        Write-Output "Inner Error: $_.ErrorDetails.Message"
                                        Write-output ""
                                    }
  
                                # check for a specific error so that we can retry the request otherwise, set the url to null so that we fall out of the loop
                                if ($_.Exception.Response.StatusCode.value__ -eq 403 )
                                    {
                                        # just ignore, leave the url the same to retry but pause first
                                        if($retryCount -ge $maxRetries)
                                            {
                                                # not going to retry again
                                                $global:Url = $null
                                                Write-Output 'Not going to retry...'
                                            }
                                        else 
                                            {
                                                $retryCount += 1
                                                write-Output ""
                                                Write-Output "Retry attempt $retryCount after a $pauseDuration second pause..."
                                                Write-output ""
                                                Start-Sleep -Seconds $pauseDuration
                                            }
                                    }
                                    else
                                        {
                                            # not going to retry -- set the url to null to fall back out of the while loop
                                            $Url = $null
                                        }
                            }
                }

        ##########################################
        # UPLOAD OF DATA
        ##########################################

            ##################################################################################################################
            # LogAnalytics upload
            ##################################################################################################################

            $DataVariable     =  ( $ResponseAllRecords  | ConvertFrom-Json).value

            Write-Output ""
            Write-Output "  Retrieved $($DataVariable.count) records from Security Center API"

            # SCOPE - Use only devices in $MachineLine
            $DataVariable     = $DataVariable | Where-Object { $_.deviceName -in $global:MachineList.computerDnsName }

            Write-Output ""
            Write-Output "  Filtered records to $($DataVariable.count) due to $($global:TargetTable) scoping"
            Write-Output ""

            #-------------------------------------------------------
            # Add Collection Time to array for each line
                    
            If ($DataVariable -eq $null)
                {
                    Write-Output "No data to upload"
                }
            Else
                {
                    $CountDataVariable = $DataVariable.count
                    $PosDataVariable   = 0
                        Do
                            {
                                $DataVariable[$PosDataVariable] | Add-Member -Type NoteProperty -Name 'CollectionTime' -Value $CollectionTime -force
                                $PosDataVariable = 1 + $PosDataVariable
                            }
                        Until ($PosDataVariable -eq $CountDataVariable)

                    #----------------------------------------------------------------------------------------------------------------------------------------------------
                    # Post to LogAnalytics - Methods supported: Legacy = HTTP Log Collector, DCR = Log Ingest API with DCRs/DCEs, Legacy_DCR = send using both methods
                    #----------------------------------------------------------------------------------------------------------------------------------------------------

                        # Legacy
                        If ( ($Global:AzLogAnalyticsAPI -eq "Legacy") -or ($Global:AzLogAnalyticsAPI -eq $null) -or ($Global:AzLogAnalyticsAPI -eq "Legacy_DCR") )
                            {    
                                $indexLoopFrom = 0

                                Do
                                    {
                                        $indexLoopTo = $indexLoopFrom + 25000

                                        Write-Output "  [$($indexLoopFrom)..$($indexLoopTo)] - Converting array-data to JSON ... Please Wait"
                                        $json = $DataVariable[$indexLoopFrom..$indexLoopTo] | ConvertTo-Json -Compress

                                        write-Output ""
                                        Write-Output "  [$($indexLoopFrom)..$($indexLoopTo)] - Posting data to Loganalytics table $($global:CustomTable) .... Please Wait !"
                                        Post-LogAnalyticsData -customerId $global:LAWS_Id -sharedKey $global:LAWS_AccessKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $CustomTable
                                        $indexLoopFrom = $indexLoopTo
                                    }

                                Until ($IndexLoopTo -ge $CountDataVariable)
                            }

                        # Modern (DCR)        
                        If ( ($Global:AzLogAnalyticsAPI -eq "DCR") -or ($Global:AzLogAnalyticsAPI -eq "Legacy_DCR") )
                            {    
                                #-------------------------------------------------------------------------------------------
                                # Variables
                                #-------------------------------------------------------------------------------------------
                
                                    $TableName    = $CustomTable + $Global:AzDcrTableNamePostfix
                                    $DataVariable = $DataVariable
                                    $VerbosePreference = "SilentlyContinue"  # Stop, Inquire, Continue, SilentlyContinue

                                #-------------------------------------------------------------------------------------------
                                # Validating/fixing schema data structure of source data
                                #-------------------------------------------------------------------------------------------

                                    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable

                                #-------------------------------------------------------------------------------------------
                                # Check if table and DCR exist, otherwise set flag to do initial setup
                                #-------------------------------------------------------------------------------------------

                                    $Status = Get-AzLogAnalyticsTableAzDataCollectionRuleExistStatus -AzLogWorkspaceResourceId $global:MainLogAnalyticsWorkspaceResourceId -TableName $TableName -TablePrefix $Global:AzDcrPrefixSrvNetworkCloud

                                #-------------------------------------------------------------------------------------------
                                # PreReq - Create/update table (DCR) in LogAnalytics to be used for upload of data via DCR/log ingestion api
                                #-------------------------------------------------------------------------------------------

                                    If ($Global:AzDcrDceTableCustomLogCreateUpdate -eq $true)
                                        {
                                            If ( $env:COMPUTERNAME -in $Global:AzDcrDceTableCustomLogCreateMasterServer)
                                                {
                                                    Create-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $global:MainLogAnalyticsWorkspaceResourceId -SchemaSourceObject $DataVariable -TableName $TableName `
                                                                                           -AzAppId $global:HighPriv_Modern_ApplicationID_Azure -AzAppSecret $global:HighPriv_Modern_Secret_Azure -TenantId $Global:TenantId


                                                    Create-AzDataCollectionRuleLogIngestCustomLog -AzLogWorkspaceResourceId $global:MainLogAnalyticsWorkspaceResourceId -SchemaSourceObject $DataVariable `
                                                                                                  -DceName $Global:AzDceNameSrvNetworkCloud -TableName $TableName -TablePrefix $Global:AzDcrPrefixSrvNetworkCloud `
                                                                                                  -LogIngestServicePricipleObjectId $Global:AzDcrLogIngestServicePrincipalObjectId `
                                                                                                  -AzDcrSetLogIngestApiAppPermissionsDcrLevel $Global:AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                                                                  -AzAppId $global:HighPriv_Modern_ApplicationID_Azure -AzAppSecret $global:HighPriv_Modern_Secret_Azure -TenantId $Global:TenantId
                                                }
                                        }

                                #-------------------------------------------------------------------------------------------
                                # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
                                #-------------------------------------------------------------------------------------------

                                    # Get DCE/DCR naming convention for prefix SRV
                                    $DcrDceNaming = Get-AzDataCollectionRuleNamingConventionSrv -TableName $TableName

                                    # Get details about DCR/DCE using Azure Resource Graph
                                    $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrDceNaming[0] -DceName $DcrDceNaming[1]
                                                                                                                 
                                    # Post deta into LogAnalytics custom log using log ingest api
                                    Post-AzLogAnalyticsLogIngestCustomLogDcrDce  -DceUri $AzDcrDceDetails[2] -DcrImmutableId $AzDcrDceDetails[6] `
                                                                                 -DcrStream $AzDcrDceDetails[7] -Data $DataVariable `
                                                                                 -AzAppId $global:HighPriv_Modern_ApplicationID_LogIngestion_DCR -AzAppSecret $global:HighPriv_Modern_Secret_LogIngestion_DCR -TenantId $Global:TenantId
                            }    # Post to LogAnalytics (DCR)
            }
    }

Function Get-ObjectSchema ($Data, $ReturnType, $ReturnFormat)
{
        <#  Troubleshooting
            $Data = $DataVariable
        #>

        $SchemaArrayLogAnalyticsTableFormat = @()
        $SchemaArrayDcrFormat = @()
        $SchemaArrayLogAnalyticsTableFormatHash = @()
        $SchemaArrayDcrFormatHash = @()

        # Requirement - Add TimeGenerated to array
        $SchemaArrayLogAnalyticsTableFormatHash += @{
                                                     name        = "TimeGenerated"
                                                     type        = "datetime"
                                                     description = ""
                                                    }

        $SchemaArrayLogAnalyticsTableFormat += [PSCustomObject]@{
                                                     name        = "TimeGenerated"
                                                     type        = "datetime"
                                                     description = ""
                                               }

        # Loop source object and build hash for table schema
        ForEach ($Entry in $Data)
            {
                $ObjColumns = $Entry | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Get-Member -MemberType NoteProperty
                ForEach ($Column in $ObjColumns)
                    {
                        $ObjDefinitionStr = $Column.Definition
                                If ($ObjDefinitionStr -like "int*")                                            { $ObjType = "int" }
                            ElseIf ($ObjDefinitionStr -like "real*")                                           { $ObjType = "int" }
                            ElseIf ($ObjDefinitionStr -like "long*")                                           { $ObjType = "long" }
                            ElseIf ($ObjDefinitionStr -like "guid*")                                           { $ObjType = "dynamic" }
                            ElseIf ($ObjDefinitionStr -like "string*")                                         { $ObjType = "string" }
                            ElseIf ($ObjDefinitionStr -like "datetime*")                                       { $ObjType = "datetime" }
                            ElseIf ($ObjDefinitionStr -like "bool*")                                           { $ObjType = "boolean" }
                            ElseIf ($ObjDefinitionStr -like "object*")                                         { $ObjType = "dynamic" }
                            ElseIf ($ObjDefinitionStr -like "System.Management.Automation.PSCustomObject*")    { $ObjType = "dynamic" }

                        # build for array check
                        $SchemaLogAnalyticsTableFormatObjHash = @{
                                                                   name        = $Column.Name
                                                                   type        = $ObjType
                                                                   description = ""
                                                                 }

                        $SchemaLogAnalyticsTableFormatObj     = [PSCustomObject]@{
                                                                   name        = $Column.Name
                                                                   type        = $ObjType
                                                                   description = ""
                                                                }
                        $SchemaDcrFormatObjHash = @{
                                                      name        = $Column.Name
                                                      type        = $ObjType
                                                   }

                        $SchemaDcrFormatObj     = [PSCustomObject]@{
                                                      name        = $Column.Name
                                                      type        = $ObjType
                                                  }


                        If ($Column.Name -notin $SchemaArrayLogAnalyticsTableFormat.name)
                            {
                                $SchemaArrayLogAnalyticsTableFormat       += $SchemaLogAnalyticsTableFormatObj
                                $SchemaArrayDcrFormat                     += $SchemaDcrFormatObj

                                $SchemaArrayLogAnalyticsTableFormatHash   += $SchemaLogAnalyticsTableFormatObjHash
                                $SchemaArrayDcrFormatHash                 += $SchemaDcrFormatObjHash
                            }
                    }
            }

            If ( ($ReturnType -eq "Table") -and ($ReturnFormat -eq "Array") )
            {
                # Return schema format for LogAnalytics table
                Return $SchemaArrayLogAnalyticsTableFormat
            }
        ElseIf ( ($ReturnType -eq "Table") -and ($ReturnFormat -eq "Hash") )
            {
                # Return schema format for DCR
                Return $SchemaArrayLogAnalyticsTableFormatHash
            }
        ElseIf ( ($ReturnType -eq "DCR") -and ($ReturnFormat -eq "Array") )
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat
            }
        ElseIf ( ($ReturnType -eq "DCR") -and ($ReturnFormat -eq "Hash") )
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormatHash
            }
        ElseIf ( ($ReturnType -eq $null) -and ($ReturnFormat -eq "Hash") )
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormatHash
            }
        ElseIf ( ($ReturnType -eq $null) -and ($ReturnFormat -eq "Array") )
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat
            }
}


Function Filter-ObjectExcludeProperty ($Data, $ExcludeProperty)
{
        $Data = $Data | Select-Object * -ExcludeProperty $ExcludeProperty
        Return $Data
}


Function Get-AzDcrListAll ($AzAppId, $AzAppSecret, $TenantId)
{
    Write-host ""
    Write-host "Getting Data Collection Rules from Azure Resource Graph .... Please Wait !"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

    #--------------------------------------------------------------------------
    # Get DCRs from Azure Resource Graph
    #--------------------------------------------------------------------------

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

        Return $Data
}


Function Get-AzDceListAll ($AzAppId, $AzAppSecret, $TenantId)
{
    Write-host ""
    Write-host "Getting Data Collection Endpoints from Azure Resource Graph .... Please Wait !"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------
        If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
            {
                $AccessTokenUri = 'https://management.azure.com/'
                $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
                $authBody       = [Ordered] @{
                                               resource = "$AccessTokenUri"
                                               client_id = "$($LogIngestAppId)"
                                               client_secret = "$($LogIngestAppSecret)"
                                               grant_type = 'client_credentials'
                                             }
                $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
                $token = $authResponse.access_token

                # Set the WebRequest headers
                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                            }
            }
        Else
            {
                $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
                $Token = $AccessToken.Token

                $Headers = @{
                                'Content-Type' = 'application/json'
                                'Accept' = 'application/json'
                                'Authorization' = "Bearer $token"
                           }
            }

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

Function Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output ($Data, $DcrName, $DceName, $AzAppId, $AzAppSecret, $TenantId, $BatchAmount)
{
        $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName -DceName $DceName `
                                               -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId

        Post-AzLogAnalyticsLogIngestCustomLogDcrDce  -DceUri $AzDcrDceDetails[2] -DcrImmutableId $AzDcrDceDetails[6] `
                                                     -DcrStream $AzDcrDceDetails[7] -Data $DataVariable -BatchAmount $BatchAmount `
                                                     -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
        
        # Write result to screen
        $DataVariable | Out-String | Write-Verbose 
}

Function CheckCreateUpdate-TableDcr-Structure ($Data, $AzLogWorkspaceResourceId, $TableName, $DcrName, $DceName, $SchemaSourceObject, `
                                               $AzAppId, $AzAppSecret, $TenantId, $LogIngestServicePricipleObjectId, $AzDcrSetLogIngestApiAppPermissionsDcrLevel)
{
    <#

        $AzLogWorkspaceResourceId                   = $LogAnalyticsWorkspaceResourceId
        $AzAppId                                    = $LogIngestAppId
        $AzAppSecret                                = $LogIngestAppSecret
        $TenantId                                   = $TenantId
        $DceName                                    = $DceName
        $DcrName                                    = $DcrName
        $TableName                                  = $TableName
        $LogIngestServicePricipleObjectId           = $AzDcrLogIngestServicePrincipalObjectId
        $AzDcrSetLogIngestApiAppPermissionsDcrLevel = $AzDcrSetLogIngestApiAppPermissionsDcrLevel

    #>

    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        If ( ($AzAppId) -and ($AzAppSecret) )
            {
                #-----------------------------------------------------------------------------------------------
                # Check if table and DCR exist - or schema must be updated due to source object schema changes
                #-----------------------------------------------------------------------------------------------

                    # Get insight about the schema structure
                    $Schema = Get-ObjectSchema -Data $DataVariable -ReturnFormat Array

                    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                                        -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId

                #-----------------------------------------------------------------------------------------------
                # Structure check = $true -> Create/update table & DCR with necessary schema
                #-----------------------------------------------------------------------------------------------

                    If ($StructureCheck -eq $true)
                        {
                            If ( ( $env:COMPUTERNAME -in $AzDcrDceTableCreateFromReferenceMachine) -or ($AzDcrDceTableCreateFromAnyMachine -eq $true) )    # manage table creations
                                {
                                    # build schema to be used for LogAnalytics Table
                                    $Schema = Get-ObjectSchema -Data $DataVariable -ReturnType Table -ReturnFormat Hash

                                    CreateUpdate-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -SchemaSourceObject $Schema -TableName $TableName `
                                                                                 -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId


                                    # build schema to be used for DCR
                                    $Schema = Get-ObjectSchema -Data $DataVariable -ReturnType DCR -ReturnFormat Hash

                                    CreateUpdate-AzDataCollectionRuleLogIngestCustomLog -AzLogWorkspaceResourceId $AzLogWorkspaceResourceId -SchemaSourceObject $Schema `
                                                                                        -DceName $DceName -DcrName $DcrName -TableName $TableName `
                                                                                        -LogIngestServicePricipleObjectId $LogIngestServicePricipleObjectId `
                                                                                        -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                                                        -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId
                                }
                        }
                } # create table/DCR
}
