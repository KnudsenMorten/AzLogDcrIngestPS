#Requires -Version 5.1

<#
    .NAME
    AzLogDcrIngestPS-DeploymentKit

    .SYNOPSIS
    The purpose of this repository is to provide everything needed to deploy a complete environment for testing AzLogDcrIngestPS together
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

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LICENSE
    Licensed under the MIT license.

    .PROJECTURI
    https://github.com/KnudsenMorten/AzLogDcrIngestPS


    .WARRANTY
    Use at your own risk, no warranty given!
#>


Write-Output "Demo for Azure Pipeline, Azure Log Ingestion API, Azure Data Collection Rules & AzLogDcrIngestPS"
Write-Output ""
Write-Output "Developed by Morten Knudsen, Microsoft MVP"
Write-Output ""
Write-Output "More information:"
Write-Output "https://github.com/KnudsenMorten/AzLogDcrIngestPS"
Write-Output ""


#------------------------------------------------------------------------------------------------------------
# Variables
#------------------------------------------------------------------------------------------------------------

    $UseRandomNumber                       = $true
    If ($UseRandomNumber)
        {
            $Number                        = [string](Get-Random -Minimum 1000 -Maximum 10000)
        }
    Else
        {
            $Number                        = "1"
        }

    # Azure App
    $AzureAppName                          = "Demo" + $Number + " - Automation - Log-Ingestion"
    $AzAppSecretName                       = "Secret used for Log-Ingestion"

    # Azure Active Directory (AAD)
    $TenantId                              = "<xxxxxx>" # "<put in your Azure AD TenantId>"

    # Azure LogAnalytics
    $LogAnalyticsSubscription              = "<xxxxxx>" # "<put in the SubId of where to place environment>"
    $LogAnalyticsResourceGroup             = "rg-logworkspaces-client-demo" + $Number  + "-t"
    $LoganalyticsWorkspaceName             = "log-management-client-demo" + $Number + "-t"
    $LoganalyticsLocation                  = "westeurope"


    # Azure Data Collection Endpoint
    $AzDceName                             = "dce-" + $LoganalyticsWorkspaceName
    $AzDceResourceGroup                    = "rg-dce-" + $LoganalyticsWorkspaceName

    # Azure Data Collection Rules
    $AzDcrResourceGroup                    = "rg-dcr-" + $LoganalyticsWorkspaceName
    $AzDcrPrefix                           = "clt"

    $VerbosePreference                     = "SilentlyContinue"  # "Continue"


#------------------------------------------------------------------------------------------------------------
# Verification download path
#------------------------------------------------------------------------------------------------------------

    # put in your path where ClientInspector, AzLogDcrIngestPS and workbooks/dashboards will be downloaded to !
    $FolderRoot = (Get-location).Path + "\" + "Demo" + $Number

    $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes","Delete"
    $no = New-Object System.Management.Automation.Host.ChoiceDescription "&No","Cancel"
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
    $heading = "Download path"
    $message = "This deployment kit will download latest files into current directory. Do you want to continue with this path? `n`n $($FolderRoot) "
    $Prompt = $host.ui.PromptForChoice($heading, $message, $options, 1)
    switch ($prompt) {
                        0
                            {
                                # Continuing
                            }
                        1
                            {
                                Write-Host "No" -ForegroundColor Red
                                Exit
                            }
                    }

    MD $FolderRoot -ErrorAction SilentlyContinue -Force | Out-Null
    CD $FolderRoot | Out-Null



#------------------------------------------------------------------------------------------------------------
# Functions
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


#------------------------------------------------------------------------------------------------------------
# Connection
#------------------------------------------------------------------------------------------------------------

    #---------------------------------------------------------
    # Connect to Azure
    #---------------------------------------------------------
        Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

        #---------------------------------------------------------
        # Get Access Token
        #---------------------------------------------------------
            $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
            $AccessToken = $AccessToken.Token

        #---------------------------------------------------------
        # Build Headers for Azure REST API with access token
        #---------------------------------------------------------
            $Headers = @{
                            "Authorization"="Bearer $($AccessToken)"
                            "Content-Type"="application/json"
                        }


    #---------------------------------------------------------
    # Connect to Microsoft Graph
    #---------------------------------------------------------
        <#
            Find-MgGraphCommand -command Add-MgApplicationPassword | Select -First 1 -ExpandProperty Permissions
        #>

        $MgScope = @(
                        "Application.ReadWrite.All",`
                        "Directory.Read.All",`
                        "Directory.AccessAsUser.All",
                        "RoleManagement.ReadWrite.Directory"
                    )


        Connect-MgGraph -TenantId $TenantId -ForceRefresh -Scopes $MgScope


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
# Building demo-setup
#-----------------------------------------------------------------------------------------------

    Write-Output ""
    Write-Output "Building demo structure in folder"
    Write-Output $ClientFolder
    Write-Output ""
    Write-Output "Downloading latest version of demo-script from https://github.com/KnudsenMorten/AzLogDcrIngestPS"
    Write-Output "into local path $($ClientFolder)"

    # download newest version
    $Download = (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/KnudsenMorten/AzLogDcrIngestPS/main/demo/Step2-Collect_CreateSchema_Send_data.ps1", "$($FolderRoot)\Step2-Collect_CreateSchema_Send_data.ps1")

    # Changing to directory where files where downloaded
    Cd $FolderRoot

#-------------------------------------------------------------------------------------
# Summarize
#-------------------------------------------------------------------------------------

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

        Notepad Step2-Collect_CreateSchema_Send_data.ps1

        Write-Output ""
        Write-Output "We are almost done ... we just need to wait approx 1 hour for Microsoft to replicate and update RBAC"
        Write-Output ""
        Write-Output "While waiting you have to copy the above variables into the Notepad file Step2-Collect_CreateSchema_Send_data.ps1 file - and save it "
        Write-Output ""
