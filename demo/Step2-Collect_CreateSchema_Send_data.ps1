#Requires -Version 5.1

<#
    .NAME
    Demo-script for AzLogDcrIngestPS, Log Ingestion API, Azure Pipeline, Azure Data Collection Rules and Azure Data Collection Endpoints

    .SYNOPSIS
    The purpose of this script is to demonstrate how you can send data, manage schema, do data-manipulation using the powershell module AzLogDcrIngestPS
    together with Log Ingestion API, Azure Pipeline, Azure Data Collection Rules and Azure Data Collection Endpoints

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LICENSE
    Licensed under the MIT license.

    .PROJECTURI
    https://github.com/KnudsenMorten/AzLogDcrIngestPS


    .WARRANTY
    Use at your own risk, no warranty given!
#>

param(
      [parameter(Mandatory=$false)]
          [ValidateSet("Download","LocalPath","PsGallery")]
          [string]$Function = "PsGallery",
      [parameter(Mandatory=$false)]
          [ValidateSet("CurrentUser","AllUsers")]
          [string]$Scope = "CurrentUser"
     )



##########################################
# VARIABLES
##########################################

<# ----- onboarding lines ----- BEGIN #>




<# ----- onboarding lines ----- END  #>


# default variables - don't remove !
$DNSName                                      = (Get-CimInstance win32_computersystem).DNSHostName +"." + (Get-CimInstance win32_computersystem).Domain
$ComputerName                                 = (Get-CimInstance win32_computersystem).DNSHostName
[datetime]$CollectionTime                      = ( Get-date ([datetime]::Now.ToUniversalTime()) -format "yyyy-MM-ddTHH:mm:ssK" )

############################################################################################################################################
# VERBOSE
############################################################################################################################################

# script run mode - normal or verbose
If ( ($psBoundParameters['verbose'] -eq $true) -or ($verbose -eq $true) )
    {
        Write-Output "Verbose mode ON"
        $global:Verbose = $true
        $VerbosePreference = "Continue"  # Stop, Inquire, Continue, SilentlyContinue
    }
Else
    {
        $global:Verbose = $false
        $VerbosePreference = "SilentlyContinue"  # Stop, Inquire, Continue, SilentlyContinue
    }


############################################################################################################################################
# FUNCTION (AzLogDcrIngestPS)
############################################################################################################################################

    # directory where the script was started
    $ScriptDirectory = $PSScriptRoot

    switch ($Function)
        {   
            "Download"
                {
                    # force download using Github. This is needed for Intune remediations, since the functions library are large, and Intune only support 200 Kb at the moment
                    Write-Output "Downloading latest version of module AzLogDcrIngestPS from https://github.com/KnudsenMorten/AzLogDcrIngestPS"
                    Write-Output "into local path $($ScriptDirectory)"

                    # delete existing file if found to download newest version
                    If (Test-Path "$($ScriptDirectory)\AzLogDcrIngestPS.psm1")
                        {
                            Remove-Item -Path "$($ScriptDirectory)\AzLogDcrIngestPS.psm1"
                        }

                     # download newest version
                    $Download = (New-Object System.Net.WebClient).DownloadFile("https://raw.githubusercontent.com/KnudsenMorten/AzLogDcrIngestPS/main/AzLogDcrIngestPS.psm1", "$($ScriptDirectory)\AzLogDcrIngestPS.psm1")
                    
                    Start-Sleep -s 3
                    
                    # load file if found - otherwise terminate
                    If (Test-Path "$($ScriptDirectory)\AzLogDcrIngestPS.psm1")
                        {
                            Import-module "$($ScriptDirectory)\AzLogDcrIngestPS.psm1" -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                        }
                    Else
                        {
                            Write-Output "Powershell module AzLogDcrIngestPS was NOT found .... terminating !"
                            break
                        }
                }

            "PsGallery"
                {
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
                }
            "LocalPath"        # Typucaly used in ConfigMgr environment (or similar) where you run the script locally
                {
                    If (Test-Path "$($ScriptDirectory)\AzLogDcrIngestPS.psm1")
                        {
                            Write-Output "Using AzLogDcrIngestPS module from local path $($ScriptDirectory)"
                            Import-module "$($ScriptDirectory)\AzLogDcrIngestPS.psm1" -Global -force -DisableNameChecking  -WarningAction SilentlyContinue
                        }
                    Else
                        {
                            Write-Output "Required Powershell function was NOT found .... terminating !"
                            Exit
                        }
                }
        }


###############################################################
# Global Variables
#
# Used to mitigate throttling in Azure Resource Graph
# Needs to be loaded after load of functions
###############################################################

    # building global variable with all DCEs, which can be viewed by Log Ingestion app
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
    # building global variable with all DCRs, which can be viewed by Log Ingestion app
    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


############################################################################################################################################
# MAIN PROGRAM
############################################################################################################################################

    #-------------------------------------------------------------------------------------------------------------
    # Initial Powershell module check - used for demo 3 only
    #-------------------------------------------------------------------------------------------------------------

        $ModuleCheck = Get-Module -Name PSWindowsUpdate -ListAvailable -ErrorAction SilentlyContinue
        If (!($ModuleCheck))
            {
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

                Write-Output ""
                Write-Output "Checking Powershell PackageProvider NuGet ... Please Wait !"
                    if (Get-PackageProvider -ListAvailable -Name NuGet -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 
                        {
                            Write-Host "  OK - PackageProvider NuGet is installed"
                        } 
                    else 
                        {
                            try {
                                Install-PackageProvider -Name NuGet -Scope AllUsers -Confirm:$false -Force
                            }
                            catch [Exception] {
                                $_.message 
                                exit
                            }
                        }

                Write-Output ""
                Write-Output "Checking Powershell Module PSWindowsUpdate ... Please Wait !"
                    if (Get-Module -ListAvailable -Name PSWindowsUpdate -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) 
                        {
                            Write-output "  OK - Powershell Modue PSWindowsUpdate is installed"
                        } 
                    else 
                        {
                            try {
                                Write-Output "  Installing Powershell Module PSWindowsUpdate .... Please Wait !"
                                Install-Module -Name PSWindowsUpdate -AllowClobber -Scope AllUsers -Confirm:$False -Force
                                Import-Module -Name PSWindowsUpdate
                            }
                            catch [Exception] {
                                $_.message 
                                exit
                            }
                        }
            }


###############################################################
# USER [1] - used as part of data-manipulation (demo)
###############################################################

    Write-Output ""
    Write-Output "Collecting User information ... Please Wait !"

    $UserLoggedOnRaw = Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique
    $UserLoggedOn    = $UserLoggedOnRaw.UserName



###################################################################################################################
# DEMO 1 - Data manipulation + show schema content
###################################################################################################################

    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
            
        $TableName  = 'Demo1InvClientComputerInfoSystem'
        $DcrName    = "dcr-" + $AzDcrPrefix + "-" + $TableName + "_CL"

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
            
        Write-Output ""
        Write-Output "Collecting Computer system information ... Please Wait !"

        $DataVariable = Get-CimInstance -ClassName Win32_ComputerSystem
        $OrgVar       = $DataVariable # used just for demo-purpose to show original content of data

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

    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
                                                           -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                           -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                           -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                           -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                           -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                           -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine

    #-----------------------------------------------------------------------------------------------
    # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
    #-----------------------------------------------------------------------------------------------

        $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                         -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    #-----------------------------------------------------------------------------------------------
    # DEMO DEEP-DIVE !!!
    #-----------------------------------------------------------------------------------------------

        #-----------------------------------------------------------------------------------------------
        # Notice: Orignal data source doesn't contain ComputerFqdn, Computer, DataCollectionTime
        # Notice: Object shows 5 data - but schema shows more properties
        #-----------------------------------------------------------------------------------------------

            # show content of $OrgVar (original data-array)
            $OrgVar[0] | fl

            # show schema of $OrgVar (original data-array)
            Get-ObjectSchemaAsArray -Data $OrgVar[0]


        #-----------------------------------------------------------------------------------------------
        # Notice: modified object (uploaded) contains Computer, ComputerFqdn, DataCollectionTime
        # Notice: modified object shows all data
        #-----------------------------------------------------------------------------------------------

            # show content of $DataVariable (modified data-array)
            $DataVariable[0] | fl

            # show schema of $DataVariable (modified data-array)
            Get-ObjectSchemaAsArray -Data $DataVariable[0]



###################################################################################################################
# DEMO 2 - Collection data -> Create LogAnalytics table + DCR + send data
###################################################################################################################

    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
            
        $TableName  = 'Demo2InvClientComputerInfoSystem'   # demo-naming !!
        $DcrName    = "dcr-" + $AzDcrPrefix + "-" + $TableName + "_CL"

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
            
        Write-Output ""
        Write-Output "Collecting Computer system information ... Please Wait !"

        $DataVariable = Get-CimInstance -ClassName Win32_ComputerSystem
    
    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

        If ($DataVariable)
            {
                # convert CIM array to PSCustomObject and remove CIM class information
                $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose

                # add Computer & ComputerFqdn info to existing array
                $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name ComputerFqdn -Column2Data $DnsName -Verbose:$Verbose

                # Validating/fixing schema data structure of source data
                $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

                # Aligning data structure with schema (requirement for DCR)
                $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
            }
        Else
            {
                $DataVariable = ""
            }


    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
                                                           -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                           -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                           -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                           -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                           -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                           -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine

    #-----------------------------------------------------------------------------------------------
    # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
    #-----------------------------------------------------------------------------------------------

        $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                         -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    #-----------------------------------------------------------------------------------------------
    # DEMO DEEP-DIVE !!!
    #-----------------------------------------------------------------------------------------------

        # show content of $DataVariable (modified data-array)
        $DataVariable[0] | fl

        # show schema of $DataVariable (modified data-array)
        Get-ObjectSchemaAsArray -Data $DataVariable[0]

        #-----------------------------------------------------------------------------------------------
        # Notice: DCR has now been created - with schema shown above

        # Notice: Azure LogAnalytics DCR table has been created - with schema shown above
        
        # Notice: Data will be coming into LogAnalytics table .... it should take approx 10-15 minutes for the Azure Pipeline to kick-in initially !
        #-----------------------------------------------------------------------------------------------

            $LogAnalyticsWorkspaceResourceId

            $TableName

            $DcrName


###################################################################################################################
# DEMO 3 - Collection of data, remove unnecessary data-properties, create schema with modified structure
###################################################################################################################

    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
            
        $TableName  = 'Demo3InvClientWindowsUpdateLastInstall'   # demo-naming !!
        $DcrName    = "dcr-" + $AzDcrPrefix + "-" + $TableName + "_CL"

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
        Write-Output ""
        Write-Output "Collecting information about installations of Windows Updates (incl. A/V updates) ... Please Wait !"

        $OsInfo = Get-CimInstance -ClassName Win32_OperatingSystem
        $ProductType = $OsInfo.ProductType  # 1 = workstation, 2 = domain controller, 3 = server

        # Collection (servers)
        If ( ($ProductType -eq "2") -or ($ProductType -eq "3") )
            {
                # Getting OS install-date
                $DaysSinceInstallDate = (Get-Date) - (Get-date $OSInfo.InstallDate)

                If ([version]$OSInfo.Version -gt "6.3.9600")  # Win2016 and higher
                    { 
                        Write-Verbose "Win2016 or higher detected (last 1000 updates incl. A/V updates)"
                        $Installed_Updates_PSWindowsUpdate_All = Get-WUHistory -MaxDate $DaysSinceInstallDate.Days -Last 1000
                    }
                ElseIf ([version]$OSInfo.Version -le "6.3.9600")  # Win2012 R2 or Win2012
                    {
                        Write-Verbose "Windows2012 / Win2012 R2 detected (last 100 updates incl. A/V updates)"
                        $Installed_Updates_PSWindowsUpdate_All = Get-WUHistory -Last 100
                    }
                Else
                    {
                        Write-Verbose "No collection of installed updates"
                        $Installed_Updates_PSWindowsUpdate_All = ""
                    }
            }

        # Collection (workstations)
        If ($ProductType -eq "1")
            {
                # Getting OS install-date
                $DaysSinceInstallDate = (Get-Date) - (Get-date $OSInfo.InstallDate)

                $Installed_Updates_PSWindowsUpdate_All = Get-WUHistory -MaxDate $DaysSinceInstallDate.Days -Last 20
            }

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

        If ($Installed_Updates_PSWindowsUpdate_All)
            {
                # Remove unnecessary columns in schema
                $DataVariable = Filter-ObjectExcludeProperty -Data $Installed_Updates_PSWindowsUpdate_All -ExcludeProperty UninstallationSteps,Categories,UpdateIdentity,UnMappedResultCode,UninstallationNotes,HResult -Verbose:$Verbose

                # convert CIM array to PSCustomObject and remove CIM class information
                $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose

                # add Computer & ComputerFqdn info to existing array
                $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name ComputerFqdn -Column2Data $DnsName -Verbose:$Verbose

                # Validating/fixing schema data structure of source data
                $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

                # Aligning data structure with schema (requirement for DCR)
                $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
            }
        Else
            {
                $DataVariable = ""
            }


    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
                                                           -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                           -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                           -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                           -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                           -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                           -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine

    #-----------------------------------------------------------------------------------------------
    # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
    #-----------------------------------------------------------------------------------------------

        $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                         -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    #-----------------------------------------------------------------------------------------------
    # DEMO DEEP-DIVE !!!
    #-----------------------------------------------------------------------------------------------

        #-----------------------------------------------------------------------------------------------
        # Notice: schema original source object ($Installed_Updates_PSWindowsUpdate_All) contains prohibited columns: Title, Date
        # Notice: There is relevant content in the prohibited columns
        #-----------------------------------------------------------------------------------------------
            Get-ObjectSchemaAsArray -Data $Installed_Updates_PSWindowsUpdate_All[0]

            $Installed_Updates_PSWindowsUpdate_All[0] | fl


        #-----------------------------------------------------------------------------------------------
        # Notice: content in some of the columns are irrelevant (should be removed) - for example UninstallationSteps, Categories
        #-----------------------------------------------------------------------------------------------
            $Installed_Updates_PSWindowsUpdate_All[0] | fl


        #-----------------------------------------------------------------------------------------------
        # Notice: modified object ($DataVariable)
        #  - irrelevant columns have been removed - for example UninstallationSteps, Categories
        #  - new column added with prohibited columns (Type_, Date_) - data has been added
        #  - prohibited columns have been removed (Type, Date)
        #-----------------------------------------------------------------------------------------------

            Get-ObjectSchemaAsArray -Data $DataVariable[0]

            $DataVariable[0]


        #-----------------------------------------------------------------------------------------------
        # Notice: DCR object + table is created with modified schema
        #-----------------------------------------------------------------------------------------------
            $LogAnalyticsWorkspaceResourceId

            $TableName + "_CL"

            $DcrName


###################################################################################################################
# DEMO 4 - Schema change existing table

# We will re-use data-set from demo 3
###################################################################################################################


    #-------------------------------------------------------------------------------------------
    # Notice: Current Schema
    #-------------------------------------------------------------------------------------------

        Get-ObjectSchemaAsArray -Data $DataVariable[0]

    #-------------------------------------------------------------------------------------------
    # Notice: object amount
    #-------------------------------------------------------------------------------------------

        $Schema = Get-ObjectSchemaAsArray -Data $DataVariable[0]
        ($Schema | Measure-Object).count


    #-------------------------------------------------------------------------------------------
    # Modifying data structure
    #-------------------------------------------------------------------------------------------

        #-------------------------------------------------------------------------------------------
        # simulation - add changes its data structure and add 2 more columns - Type & MyNewColumn
        #-------------------------------------------------------------------------------------------

            $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name "Type" -Column1Data "MyDataType" -Verbose:$Verbose
            $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name "MyNewColumn" -Column1Data "MyId" -Verbose:$Verbose


        #-------------------------------------------------------------------------------------------
        # Notice: object has changed - 2 more columns + data added (Type, MyNewColumn) - one is OK - one is prohibited
        #-------------------------------------------------------------------------------------------

            $DataVariable[0]

            Get-ObjectSchemaAsArray -Data $DataVariable[0]

            $Schema = Get-ObjectSchemaAsArray -Data $DataVariable[0]
            ($Schema | Measure-Object).count


        #-------------------------------------------------------------------------------------------
        # Validating/fixing schema data structure of source data
        #-------------------------------------------------------------------------------------------

            $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

            $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose


        #-------------------------------------------------------------------------------------------
        # Notice: object is changed
        # - New property Type_ is created
        # - Data is moved to the new column (Type_)
        # - The prohibited property Type is removed
        #-------------------------------------------------------------------------------------------

            $DataVariable[0]

            Get-ObjectSchemaAsArray -Data $DataVariable[0]

            $Schema = Get-ObjectSchemaAsArray -Data $DataVariable[0]
            ($Schema | Measure-Object).count


        # Now we will send the data to LogAnalytics

    #-------------------------------------------------------------------------------------------
    # Create/Update Schema for LogAnalytics Table & Data Collection Rule schema
    #-------------------------------------------------------------------------------------------

        $ResultMgmt = CheckCreateUpdate-TableDcr-Structure -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId `
                                                           -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose `
                                                           -DceName $DceName -DcrName $DcrName -DcrResourceGroup $AzDcrResourceGroup -TableName $TableName -Data $DataVariable `
                                                           -LogIngestServicePricipleObjectId $AzDcrLogIngestServicePrincipalObjectId `
                                                           -AzDcrSetLogIngestApiAppPermissionsDcrLevel $AzDcrSetLogIngestApiAppPermissionsDcrLevel `
                                                           -AzLogDcrTableCreateFromAnyMachine $AzLogDcrTableCreateFromAnyMachine `
                                                           -AzLogDcrTableCreateFromReferenceMachine $AzLogDcrTableCreateFromReferenceMachine

    #-----------------------------------------------------------------------------------------------
    # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
    #-----------------------------------------------------------------------------------------------

        $ResultPost = Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                                         -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


        #-----------------------------------------------------------------------------------------------
        # Notice: DCR object + table is created with modified schema
        #-----------------------------------------------------------------------------------------------
            $LogAnalyticsWorkspaceResourceId

            $TableName + "_CL"


        #-------------------------------------------------------------------------------------------
        # Notice: schema is +1 in LogAnalytics table (=18) because of new property TimeGenerated as part of transformKql
        #-------------------------------------------------------------------------------------------

            # building global variable with all DCRs, which can be viewed by Log Ingestion app
            $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

            $Dcr = $global:AzDcrDetails | Where-Object { $_.name -eq $DcrName }

            Get-AzDataCollectionRuleTransformKql -DcrResourceId $Dcr.id


        #-------------------------------------------------------------------------------------------
        # Notice: After approx 10-12 min. we will see the data with the modified schema
        #-------------------------------------------------------------------------------------------

