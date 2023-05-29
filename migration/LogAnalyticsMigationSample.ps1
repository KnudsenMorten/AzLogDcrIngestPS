#############################################################################
# Azure LogAnalytics Migration Demo
# ------------------------------------
# Demo #2 - Migration of existing table to V2-format

# Prepared by Morten Knudsen, Microsoft MVP (https://mortenknudsen.net)
#############################################################################

    # Demo number for custom table
    $DemoNumber                     = (Get-Random -Maximum 10000)

    # default
    $UserLoggedOnRaw                = Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique
    $UserLoggedOn                   = $UserLoggedOnRaw.UserName
    $DNSName                        = (Get-CimInstance win32_computersystem).DNSHostName +"." + (Get-CimInstance win32_computersystem).Domain
    $ComputerName                   = (Get-CimInstance win32_computersystem).DNSHostName
    [datetime]$CollectionTime       = ( Get-date ([datetime]::Now.ToUniversalTime()) -format "yyyy-MM-ddTHH:mm:ssK" )

    #------------------------------------------------------------------------------------------------------------
    # PreReq Functions
    #------------------------------------------------------------------------------------------------------------

        Write-Output "Checking needed functions ... Please Wait !"
        $ModuleCheck = Get-Module -Name Az.Resources -ListAvailable -ErrorAction SilentlyContinue
        If (!($ModuleCheck))
            {
                Write-Output "Installing Az-module in CurrentUser scope ... Please Wait !"
                Install-module -Name Az -Force -Scope CurrentUser
            }

        $ModuleCheck = Get-Module -Name Microsoft.Graph -ListAvailable -ErrorAction SilentlyContinue
        If (!($ModuleCheck))
            {
                Write-Output "Installing Microsoft.Graph in CurrentUser scope ... Please Wait !"
                Install-module -Name Microsoft.Graph -Force -Scope CurrentUser
            }

        <#
            Install-module Az -Scope CurrentUser
            Install-module Microsoft.Graph -Scope CurrentUser
            install-module Az.portal -Scope CurrentUser

            Import-module Az -Scope CurrentUser
            Import-module Az.Accounts -Scope CurrentUser
            Import-module Az.Resources -Scope CurrentUser
            Import-module Microsoft.Graph.Applications -Scope CurrentUser
            Import-Module Microsoft.Graph.DeviceManagement.Enrolment -Scope CurrentUser
        #>

#-------------------------------------------------------------------------------------------------------------
Function AzLogAnalytics-V1-Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource)
#-------------------------------------------------------------------------------------------------------------
{
    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

Function AzLogAnalytics-V1-Post-Data ($customerId, $sharedKey, $body, $logType)
{
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $body.Length
    $signature = AzLogAnalytics-V1-Build-Signature `
        -customerId $customerId `
        -sharedKey $sharedKey `
        -date $rfc1123date `
        -contentLength $contentLength `
        -method $method `
        -contentType $contentType `
        -resource $resource
    $uri = "https://" + $customerId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"

    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $logType;
        "x-ms-date" = $rfc1123date;
        "time-generated-field" = $TimeStampField;
    }

        Try {
                $response = Invoke-WebRequest -Uri $uri -Method $method -ContentType $contentType -Headers $headers -Body $body -UseBasicParsing
            }
     Catch
            {
                $_.Exception.Message
                If ($_.Exception.Message -eq '200')    {   Write-host "Upload to Azure LogAnalytics completed successfully !"   }
            }
}




#############################################################################
# AzureLogAnalytics (V1)
#############################################################################
#region section v1

    #----------------------------------------------------------------------------
    # (1) Variables
    #----------------------------------------------------------------------------
        $TenantId                       = "f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e"

        # Destination
        $LogAnalyticsWorkspaceId        = "fff35227-7f8d-45ab-9670-c87ed13a36ee"
        $LogAnalyticsWorkspaceAccessKey = "4F4CSeQ8McSO3tLBrNGwNtaci5lvsKNul9cVcDERCVU1fcTh+8qYHS85Dt/Cm5fHVLfECXY82vbPQTqVctFVDA=="
        $LogAnalyticsCustomTable        = "V1CustomTable" + $DemoNumber

    #----------------------------------------------------------------------------
    # (2) Connectivity to Azure
    #----------------------------------------------------------------------------
        Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

    #----------------------------------------
    # (3) Data to Upload (sample)
    #----------------------------------------

        $DataVariable = @()

        $item = New-Object PSObject
        $item | Add-Member -type NoteProperty -Name 'Computer' -Value $Env:ComputerName
        $item | Add-Member -type NoteProperty -Name 'ColumnString' -Value 'StringText'
        $item | Add-Member -type NoteProperty -Name 'ColumnDate' -Value (Get-date)
        $item | Add-Member -type NoteProperty -Name 'ColumnNumber' -Value (Get-random -max 10000)
       # $item | Add-Member -type NoteProperty -Name 'ColumnStringExtra' -Value "Extra"

        $DataVariable += $item

    #----------------------------------------
    # (4) Upload to LogAnalytics
    #----------------------------------------
        $TimeStampField   = "" 
        $json = $DataVariable | ConvertTo-Json -Compress

        Write-host "Sending data to custom table (v1): $($LogAnalyticsCustomTable)"
        AzLogAnalytics-V1-Post-Data -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsWorkspaceAccessKey -body ([System.Text.Encoding]::UTF8.GetBytes($json)) -logType $LogAnalyticsCustomTable

#endregion


#############################################################################
# AzureLogAnalytics (V2)
#############################################################################

    #----------------------------------------------------------------------------
    # (1) Variables (Prereq, setup environment)
    #----------------------------------------------------------------------------
        $TenantId                              = "xxxxxx"

        # Azure App
        $AzureAppName                          = "DemoMigration - Automation - Log-Ingestion"
        $AzAppSecretName                       = "Secret used for Log-Ingestion"
        $AzAppSecret                           = "xxxxxxx"

        # Azure LogAnalytics
        $LogAnalyticsSubscription              = "xxxxxx"
        $LogAnalyticsResourceGroup             = "rg-loganalyticsv2demo"
        $LoganalyticsWorkspaceName             = "log-loganalyticsv2-migration-demo"
        $LoganalyticsLocation                  = "westeurope"

        # Azure Data Collection Endpoint
        $AzDceName                             = "dce-log-loganalyticsv2-migration-demo"
        $AzDceResourceGroup                    = "rg-dce-log-loganalyticsv2-migration-demo"

        # Azure Data Collection Rules
        $AzDcrResourceGroup                    = "rg-dcr-log-loganalyticsv2-migration-demo"
        $AzDcrPrefix                           = "demo"

        $VerbosePreference                     = "SilentlyContinue"  # "Continue"

    #----------------------------------------------------------------------------
    # (2) Connectivity
    #----------------------------------------------------------------------------
        # Connect to Azure
        Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

        # Get Access Token
        $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
        $AccessToken = $AccessToken.Token

        # Build Headers for Azure REST API with access token
        $Headers = @{
                        "Authorization"="Bearer $($AccessToken)"
                        "Content-Type"="application/json"
                    }


        # Connect to Microsoft Graph
        $MgScope = @(
                        "Application.ReadWrite.All",`
                        "Directory.Read.All",`
                        "Directory.AccessAsUser.All",
                        "RoleManagement.ReadWrite.Directory"
                    )
        Connect-MgGraph -TenantId $TenantId -ForceRefresh -Scopes $MgScope

    #region section prereqv2
    #-------------------------------------------------------------------------------------------
    # (3) Pre-requisite - deployment of environment (if missing)
    #-------------------------------------------------------------------------------------------

        <#
        The purpose of this section is to provide everything needed to deploy a complete environment for testing AzLogDcrIngestPS together
        with Log Ingestion API, Azure Pipeline, Azure Data Collection Rules and Azure Data Collection Endpoints

        The deployment includes the following steps:

        (1)  create Azure Resource Group for Azure LogAnalytics Workspace
        (2)  create Azure LogAnalytics Workspace
        (3)  create Azure App registration used for upload of data by demo-upload script
        (4)  create Azure service principal on Azure App
        (5)  create needed secret on Azure app
        (6)  create the Azure Resource Group for Azure Data Collection Endpoint (DCE) in same region as Azure LogAnalytics Workspace
        (7)  create the Azure Resource Group for Azure Data Collection Rules (DCR) in same region as Azure LogAnalytics Workspace
        (8)  create Azure Data Collection Endpoint (DCE) in same region as Azure LogAnalytics Workspace
        (9)  delegate permissions for Azure App on LogAnalytics workspace
        (10) delegate permissions for Azure App on Azure Resource Group for Azure Data Collection Rules (DCR)
        (11) delegate permissions for Azure App on Azure Resource Group for Azure Data Collection Endpoints (DCE)
        #>

        #-------------------------------------------------------------------------------------
        # Azure Context
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure context is subscription [ $($LogAnalyticsSubscription) ]"
            $AzContext = Get-AzContext
                If ($AzContext.Subscription -ne $LogAnalyticsSubscription )
                    {
                        Write-Output ""
                        Write-Output "Switching Azure context to subscription [ $($LogAnalyticsSubscription) ]"
                        $AzContext = Set-AzContext -Subscription $LogAnalyticsSubscription -Tenant $TenantId
                    }

        #-------------------------------------------------------------------------------------
        # Create the resource group for Azure LogAnalytics workspace
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure resource group exist [ $($LogAnalyticsResourceGroup) ]"
            try {
                Get-AzResourceGroup -Name $LogAnalyticsResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating Azure resource group [ $($LogAnalyticsResourceGroup) ]"
                New-AzResourceGroup -Name $LogAnalyticsResourceGroup -Location $LoganalyticsLocation
            }

        #-------------------------------------------------------------------------------------
        # Create the workspace
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure LogAnalytics workspace exist [ $($LoganalyticsWorkspaceName) ]"
            try {
                $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating LogAnalytics workspace [ $($LoganalyticsWorkspaceName) ] in $LogAnalyticsResourceGroup"
                New-AzOperationalInsightsWorkspace -Location $LoganalyticsLocation -Name $LoganalyticsWorkspaceName -Sku PerGB2018 -ResourceGroupName $LogAnalyticsResourceGroup
            }

        #-------------------------------------------------------------------------------------
        # Get workspace details
        #-------------------------------------------------------------------------------------

            $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
    
            $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

        #-------------------------------------------------------------------------------------
        # Create Azure app registration
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure App [ $($AzureAppName) ]"
            $AppCheck = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'" -ErrorAction Stop
                If ($AppCheck -eq $null)
                    {
                        Write-Output ""
                        Write-host "Creating Azure App [ $($AzureAppName) ]"
                        $AzureApp = New-MgApplication -DisplayName $AzureAppName
                    }

        #-------------------------------------------------------------------------------------
        # Create service principal on Azure app
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure Service Principal on App [ $($AzureAppName) ]"
            $AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"

            $AppId    = $AppInfo.AppId
            $ObjectId = $AppInfo.Id

            $ServicePrincipalCheck = Get-MgServicePrincipal -Filter "AppId eq '$AppId'"
                If ($ServicePrincipalCheck -eq $null)
                    {
                        Write-Output ""
                        Write-host "Creating Azure Service Principal on App [ $($AzureAppName) ]"
                        $ServicePrincipal = New-MgServicePrincipal -AppId $AppId
                    }

        #-------------------------------------------------------------------------------------
        # Create secret on Azure app
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure Secret on App [ $($AzureAppName) ]"
            $AppInfo  = Get-MgApplication -Filter "AppId eq '$AppId'"

            $AppId    = $AppInfo.AppId
            $ObjectId = $AppInfo.Id

                If ($AzAppSecretName -notin $AppInfo.PasswordCredentials.DisplayName)
                    {
                        Write-Output ""
                        Write-host "Creating Azure Secret on App [ $($AzureAppName) ]"

                        $passwordCred = @{
                            displayName = $AzAppSecretName
                            endDateTime = (Get-Date).AddYears(1)
                        }

                        $AzAppSecret = (Add-MgApplicationPassword -applicationId $ObjectId -PasswordCredential $passwordCred).SecretText
                        Write-Output ""
                        Write-Output "Secret with name [ $($AzAppSecretName) ] created on app [ $($AzureAppName) ]"
                        Write-Output $AzAppSecret
                        Write-Output ""
                        Write-Output "AppId for app [ $($AzureAppName) ] is"
                        Write-Output $AppId
                    }

        #-------------------------------------------------------------------------------------
        # Create the resource group for Data Collection Endpoints (DCE) in same region as LA
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure resource group exist [ $($AzDceResourceGroup) ]"
            try {
                Get-AzResourceGroup -Name $AzDceResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating Azure resource group [ $($AzDceResourceGroup) ]"
                New-AzResourceGroup -Name $AzDceResourceGroup -Location $LoganalyticsLocation
            }

        #-------------------------------------------------------------------------------------
        # Create the resource group for Data Collection Rules (DCR) in same region as LA
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure resource group exist [ $($AzDcrResourceGroup) ]"
            try {
                Get-AzResourceGroup -Name $AzDcrResourceGroup -ErrorAction Stop
            } catch {
                Write-Output ""
                Write-Output "Creating Azure resource group [ $($AzDcrResourceGroup) ]"
                New-AzResourceGroup -Name $AzDcrResourceGroup -Location $LoganalyticsLocation
            }

        #-------------------------------------------------------------------------------------
        # Create Data Collection Endpoint
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Validating Azure Data Collection Endpoint exist [ $($AzDceName) ]"
        
            $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
            Try
                {
                    Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers
                }
            Catch
                {
                    Write-Output ""
                    Write-Output "Creating/updating DCE [ $($AzDceName) ]"

                    $DceObject = [pscustomobject][ordered]@{
                                    properties = @{
                                                    description = "DCE for LogIngest to LogAnalytics $LoganalyticsWorkspaceName"
                                                    networkAcls = @{
                                                                        publicNetworkAccess = "Enabled"

                                                                    }
                                                    }
                                    location = $LogAnalyticsLocation
                                    name = $AzDceName
                                    type = "Microsoft.Insights/dataCollectionEndpoints"
                                }

                    $DcePayload = $DceObject | ConvertTo-Json -Depth 20

                    $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"

                    Try
                        {
                            Invoke-WebRequest -Uri $DceUri -Method PUT -Body $DcePayload -Headers $Headers
                        }
                    Catch
                        {
                        }
                }
        
        #-------------------------------------------------------------------------------------
        # Sleeping 1 min to let Azure AD replicate before doing delegation
        #-------------------------------------------------------------------------------------

            Write-Output "Sleeping 1 min to let Azure AD replicate before doing delegation"
            Start-Sleep -s 60

        #-------------------------------------------------------------------------------------
        # Delegation permissions for Azure App on LogAnalytics workspace
        # Needed for table management - not needed for log ingestion - for simplifity it is setup when having 1 app
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on Loganalytics workspace [ $($LoganalyticsWorkspaceName) ]"

            $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
    
            $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

            $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
            $DcrRgResourceId          = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

            # Contributor on LogAnalytics workspacespace
                $guid = (new-guid).guid
                $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
                $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
                $roleUrl = "https://management.azure.com" + $LogAnalyticsWorkspaceResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
                $roleBody = @{
                    properties = @{
                        roleDefinitionId = $roleDefinitionId
                        principalId      = $ServicePrincipalObjectId
                        scope            = $LogAnalyticsWorkspaceResourceId
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


        #-------------------------------------------------------------------------------------
        # Delegation permissions for Azure App on DCR Resource Group
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on RG [ $($AzDcrResourceGroup) ]"

            $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
            $AzDcrRgResourceId        = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

            # Contributor
                $guid = (new-guid).guid
                $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
                $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
                $roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
                $roleBody = @{
                    properties = @{
                        roleDefinitionId = $roleDefinitionId
                        principalId      = $ServicePrincipalObjectId
                        scope            = $AzDcrRgResourceId
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

            Write-Output ""
            Write-Output "Setting Monitoring Metrics Publisher permissions for app [ $($AzureAppName) ] on RG [ $($AzDcrResourceGroup) ]"

            # Monitoring Metrics Publisher
                $guid = (new-guid).guid
                $monitorMetricsPublisherRoleId = "3913510d-42f4-4e42-8a64-420c390055eb"
                $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($monitorMetricsPublisherRoleId)"
                $roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
                $roleBody = @{
                    properties = @{
                        roleDefinitionId = $roleDefinitionId
                        principalId      = $ServicePrincipalObjectId
                        scope            = $AzDcrRgResourceId
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

        #-------------------------------------------------------------------------------------
        # Delegation permissions for Azure App on DCE Resource Group
        #-------------------------------------------------------------------------------------

            Write-Output ""
            Write-Output "Setting Contributor permissions for app [ $($AzDceName) ] on RG [ $($AzDceResourceGroup) ]"

            $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
            $AzDceRgResourceId        = (Get-AzResourceGroup -Name $AzDceResourceGroup).ResourceId

            # Contributor
                $guid = (new-guid).guid
                $ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
                $roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
                $roleUrl = "https://management.azure.com" + $AzDceRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
                $roleBody = @{
                    properties = @{
                        roleDefinitionId = $roleDefinitionId
                        principalId      = $ServicePrincipalObjectId
                        scope            = $AzDceRgResourceId
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

        #-----------------------------------------------------------------------------------------------
        # Summarize Environment
        #-----------------------------------------------------------------------------------------------

        # Azure App
            Write-Output ""
            Write-Output "Tenant Id:"
            Write-Output $TenantId

        # Azure App
            $AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"
            $AppId    = $AppInfo.AppId
            $ObjectId = $AppInfo.Id

            Write-Output ""
            Write-Output "LogIngestion Azure App Name:"
            Write-Output $AzureAppName

            Write-Output ""
            Write-Output "LogIngestion Azure App Id:"
            Write-Output $AppId
            Write-Output ""


            If ($AzAppSecret)
                {
                    Write-Output "LogIngestion Azure App Secret:"
                    Write-Output $AzAppSecret
                }
            Else
                {
                    Write-Output "LogIngestion Azure App Secret:"
                    Write-Output "N/A (new secret must be made)"
                }

        # Azure Service Principal for App
            $ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
            Write-Output ""
            Write-Output "LogIngestion Azure Service Principal Object Id for app:"
            Write-Output $ServicePrincipalObjectId

        # Azure Loganalytics
            Write-Output ""
            $LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
            $LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

            Write-Output ""
            Write-Output "Azure LogAnalytics Workspace Resource Id:"
            Write-Output $LogAnalyticsWorkspaceResourceId

        # DCE
            $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
            $DceObj = Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers

            $AzDceLogIngestionUri = $DceObj.properties.logsIngestion[0].endpoint

            Write-Output ""
            Write-Output "Azure Data Collection Endpoint Name:"
            Write-Output $AzDceName

            Write-Output ""
            Write-Output "Azure Data Collection Endpoint Log Ingestion Uri:"
            Write-Output $AzDceLogIngestionUri
            Write-Output ""
            Write-Output "-------------------------------------------------"
            Write-Output ""
            Write-Output "Please insert these lines into Demo-script:"
            Write-Output ""
            Write-Output "`$TenantId                                     = `"$($TenantId)`" "
            Write-Output "`$LogIngestAppId                               = `"$($AppId)`" "
            Write-Output "`$LogIngestAppSecret                           = `"$($AzAppSecret)`" "
            Write-Output ""
            Write-Output "`$DceName                                      = `"$AzDceName`" "
            Write-Output "`$AzDcrResourceGroup                           = `"$($AzDcrResourceGroup)`" "
            Write-Output "`$AzDcrPrefix                                  = `"$($AzDcrPrefix)`" "
            Write-Output ""
            Write-Output "`$LogAnalyticsWorkspaceResourceId              = "
            Write-Output "`"$($LogAnalyticsWorkspaceResourceId)`" "
            Write-Output ""
            Write-Output "`$AzDcrSetLogIngestApiAppPermissionsDcrLevel   = `$false"
            Write-Output "`$AzDcrLogIngestServicePrincipalObjectId       = `"$($ServicePrincipalObjectId)`" "
            Write-Output ""
            Write-Output "`$AzLogDcrTableCreateFromReferenceMachine      = @()"
            Write-Output "`$AzLogDcrTableCreateFromAnyMachine            = `$true"

        #-------------------------------------------------------------------------------------------
        # PS Module check - AzLogDcrIngestPS
        #-------------------------------------------------------------------------------------------
            # check for AzLogDcrIngestPS
            $ModuleCheck = Get-Module -Name AzLogDcrIngestPS -ListAvailable -ErrorAction SilentlyContinue
            If (!($ModuleCheck))
                {
                    # check for NuGet package provider
                    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                    Write-Output ""
                    Write-Output "Checking Powershell PackageProvider NuGet ... Please Wait !"
                        if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 
                            {
                                Write-Host "OK - PackageProvider NuGet is installed"
                            } 
                        else 
                            {
                                try
                                    {
                                        Write-Host "Installing NuGet package provider .. Please Wait !"
                                        Install-PackageProvider -Name NuGet -Scope $Scope -Confirm:$false -Force
                                    }
                                catch [Exception] {
                                    $_.message 
                                    exit
                                }
                            }

                    Write-Output "Powershell module AzLogDcrIngestPS was not found !"
                    Write-Output "Installing latest version from PsGallery in scope $Scope .... Please Wait !"

                    Install-module -Name AzLogDcrIngestPS -Repository PSGallery -Force -Scope $Scope
                    import-module -Name AzLogDcrIngestPS -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                }

            Elseif ($ModuleCheck)
                {
                    # sort to get highest version, if more versions are installed
                    $ModuleCheck = Sort-Object -Descending -Property Version -InputObject $ModuleCheck
                    $ModuleCheck = $ModuleCheck[0]

                    Write-Output "Checking latest version at PsGallery for AzLogDcrIngestPS module"
                    $online = Find-Module -Name AzLogDcrIngestPS -Repository PSGallery

                    #compare versions
                    if ( ([version]$online.version) -gt ([version]$ModuleCheck.version) ) 
                        {
                            Write-Output "Newer version ($($online.version)) detected"
                            Write-Output "Updating AzLogDcrIngestPS module .... Please Wait !"
                            Update-module -Name AzLogDcrIngestPS -Force
                            import-module -Name AzLogDcrIngestPS -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                        }
                    else
                        {
                            # No new version detected ... continuing !
                            Write-Output "OK - Running latest version"
                            $UpdateAvailable = $False
                            import-module -Name AzLogDcrIngestPS -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                        }
                }
        #endregion



    #-------------------------------------------------------------------------------------------
    # (4) Variables - LogAnalytics v2-format
    #-------------------------------------------------------------------------------------------

        $TableName                                    = "V1CustomTable" + $DemoNumber

        $TenantId                                     = "xxxxxxx" 
        $LogIngestAppId                               = "xxxxxxx" 
        $LogIngestAppSecret                           = "xxxxxxx" 

        $DceName                                      = "dce-log-loganalyticsv2-migration-demo" 
        $AzDcrResourceGroup                           = "rg-dcr-log-loganalyticsv2-migration-demo" 

        $LogAnalyticsWorkspaceResourceId              = "/subscriptions/xxxxxxxxxxx/resourceGroups/rg-loganalyticsv2demo/providers/Microsoft.OperationalInsights/workspaces/log-loganalyticsv2-migration-demo" 

        $AzDcrSetLogIngestApiAppPermissionsDcrLevel   = $false
        $AzDcrLogIngestServicePrincipalObjectId       = "xxxxx" 

        $AzLogDcrTableCreateFromReferenceMachine      = @()
        $AzLogDcrTableCreateFromAnyMachine            = $true
        $DcrName                                      = "dcr-demo-" + $TableName + "_CL"

        $Verbose                                      = $true

pause

    #-------------------------------------------------------------------------------------------
    # (5A) Migration of existing table to V2-format (DCR-based)
    #-------------------------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $LogIngestAppId `
                                               -AzAppSecret $LogIngestAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

        # Get existing LA table info
            $TableUrl = "https://management.azure.com" + $LogAnalyticsWorkspaceResourceId + "/tables?api-version=2021-12-01-preview"
            $tbl = invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
            $res = $tbl.value.properties | Where-Object { $_.schema.name -like "*$($DemoNumber)*" }
            $res.schema
            $res.schema.columns
            pause

        # Migrate table to v2 (DCR-based)
            $Uri         = "https://management.azure.com" + $LogAnalyticsWorkspaceResourceId + "/tables/$($TableName)_CL/migrate?api-version=2021-12-01-preview"
            $Response    = invoke-webrequest -UseBasicParsing -Method POST -Uri $Uri -Headers $Headers

    #-------------------------------------------------------------------------------------------
    # (5B) Create a DCR based on existing LA table schema in Migrate-mode
    #-------------------------------------------------------------------------------------------

            #----------------------------------------
            # (M1) Data to Upload (sample)
            #----------------------------------------
                $DataVariable = @()

                $item = New-Object PSObject
                $item | Add-Member -type NoteProperty -Name 'Computer' -Value $Env:ComputerName
                $item | Add-Member -type NoteProperty -Name 'ColumnString' -Value 'StringText'
                $item | Add-Member -type NoteProperty -Name 'ColumnDate' -Value (Get-date)
                $item | Add-Member -type NoteProperty -Name 'ColumnNumber' -Value (Get-random -max 10000)
                #$item | Add-Member -type NoteProperty -Name 'ColumnStringExtra' -Value "Extra"

                $DataVariable += $item


            #-------------------------------------------------------------------------------------------
            # (M2) Get info about DCEs & DCRs
            #-------------------------------------------------------------------------------------------

                # building global variable with all DCEs, which can be viewed by Log Ingestion app
                $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
                # building global variable with all DCRs, which can be viewed by Log Ingestion app
                $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


            #----------------------------------------
            # (M3) Data Manipulation
            #----------------------------------------

                If ($DataVariable)
                    {
                        # add CollectionTime to existing array
                        $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose

                        # add Computer, ComputerFqdn & UserLoggedOn info to existing array
                        $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name ComputerFqdn -Column2Data $DnsName -Column3Name UserLoggedOn -Column3Data $UserLoggedOn -Verbose:$Verbose

                        # Validating/fixing schema data structure of source data
                        $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

                        # Aligning data structure with schema (requirement for DCR)
                        $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
                }


            #-------------------------------------------------------------------------------------------
            # (M4) Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
            #-------------------------------------------------------------------------------------------

                If ($DataVariable)
                    {

                        $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaMode Migrate `
                                                                            -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                                            -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                                            -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                                            -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                                            -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                                            -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine
                    }


            #-------------------------------------------------------------------------------------------
            # (M5) Get info about infrastructure
            #-------------------------------------------------------------------------------------------

                # building global variable with all DCEs, which can be viewed by Log Ingestion app
                $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
                # building global variable with all DCRs, which can be viewed by Log Ingestion app
                $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose



    ###################################################################

    #----------------------------------------
    # (6) Data to Upload (sample)
    #----------------------------------------
        $DataVariable = @()
        [double]$RandomNumber = (Get-random -max 10000)
        $item = New-Object PSObject
        $item | Add-Member -type NoteProperty -Name 'Computer' -Value $Env:ComputerName
        $item | Add-Member -type NoteProperty -Name 'ColumnString' -Value 'StringText'
        $item | Add-Member -type NoteProperty -Name 'ColumnDate' -Value (Get-date)
        $item | Add-Member -type NoteProperty -Name 'ColumnNumber' -Value $RandomNumber
        #$item | Add-Member -type NoteProperty -Name 'ColumnStringExtra' -Value "Extra"

        $DataVariable += $item


    #-------------------------------------------------------------------------------------------
    # (7) Get info about DCEs & DCRs
    #-------------------------------------------------------------------------------------------

        # building global variable with all DCEs, which can be viewed by Log Ingestion app
        $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
        # building global variable with all DCRs, which can be viewed by Log Ingestion app
        $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    #----------------------------------------
    # (8) Data Manipulation
    #----------------------------------------

        If ($DataVariable)
            {
                # add CollectionTime to existing array
                $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose

                # add Computer, ComputerFqdn & UserLoggedOn info to existing array
                $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name ComputerFqdn -Column2Data $DnsName -Column3Name UserLoggedOn -Column3Data $UserLoggedOn -Verbose:$Verbose

                # Validating/fixing schema data structure of source data
                $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

                # Aligning data structure with schema (requirement for DCR)
                $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
        }


    #-------------------------------------------------------------------------------------------
    # (9) Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        If ($DataVariable)
            {

                $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaMode Merge `
                                                                    -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                                    -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                                    -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                                    -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                                    -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                                    -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine
            }

        
    #-----------------------------------------------------------------------------------------------
    # (10) Upload data to LogAnalytics using DCR / DCE / Log Ingestion API (LogAnalytics v2)
    #-----------------------------------------------------------------------------------------------

        If ($DataVariable)
            {
                $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                                 -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
            } # If $DataVariable


###################################################################
# (11) Transform data into old fields
###################################################################

pause

    $transformKql = "source | extend TimeGenerated = now(), ColumnDate_value_t = ColumnDate, ColumnString_s = ColumnString"

    $DcrResourceId = ($global:AzDcrDetails | Where-Object { $_.name -eq $DcrName }).id
    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$Verbose

    Get-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId 


    #-----------------------------------------------------------------------------------------------
    # (12) Upload data to LogAnalytics using DCR / DCE / Log Ingestion API with transformation
    #-----------------------------------------------------------------------------------------------

        If ($DataVariable)
            {
                $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                                 -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
            } # If $DataVariable
