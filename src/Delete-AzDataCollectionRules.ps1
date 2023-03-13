Function Delete-AzDataCollectionRules
{
 <#
    .SYNOPSIS
    Deletes the Azure Loganalytics defined in like-format, so you can fast clean-up for example after demo or testing

    .DESCRIPTION
    Used to delete many data collection rules in one task

    .PARAMETER DcrnameLike
    Here you can put in the DCR name(s) you want to delete using like-format - sample *demo* 

    .PARAMETER AzLogWorkspaceResourceId
    This is resource id of the Azure LogAnalytics workspace

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
    $verbose                                         = $true
    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    # delete Azure LogAnalytics data collection rules - based on name - NOTE: tenant-wide (use with caution) - DcrNameLike can include wildcard like *demo*
    Delete-AzDataCollectionRules -DcrNameLike "*test*" -Verbose:$true

    # Output
    VERBOSE: Sent top=1000 skip=0 skipToken=
    VERBOSE: Received results: 69
    Data Collection Rules deletions in scope:
    dcr-clt1-InvClientComputerOSInfoTest3V2_CL
    dcr-clt1-InvClientComputerOSInfoTest4V2_CL
    dcr-clt1-InvClientComputerOSInfoTest5V2_CL
    dcr-clt1-InvClientComputerOSInfoTESTV2_CL
    Deleting Data Collection Rules [ dcr-clt1-InvClientComputerOSInfoTest3V2_CL ] ... Please Wait !


    Headers    : {[Pragma, System.String[]], [Request-Context, System.String[]], [x-ms-correlation-request-id, System.String[]], [x-ms-client
                 -request-id, System.String[]]...}
    Version    : 1.1
    StatusCode : 200
    Method     : DELETE
    Content    : 

    Deleting Data Collection Rules [ dcr-clt1-InvClientComputerOSInfoTest4V2_CL ] ... Please Wait !
    Headers    : {[Pragma, System.String[]], [Request-Context, System.String[]], [x-ms-correlation-request-id, System.String[]], [x-ms-client
                 -request-id, System.String[]]...}
    Version    : 1.1
    StatusCode : 200
    Method     : DELETE
    Content    : 

    Deleting Data Collection Rules [ dcr-clt1-InvClientComputerOSInfoTest5V2_CL ] ... Please Wait !
    Headers    : {[Pragma, System.String[]], [Request-Context, System.String[]], [x-ms-correlation-request-id, System.String[]], [x-ms-client
                 -request-id, System.String[]]...}
    Version    : 1.1
    StatusCode : 200
    Method     : DELETE
    Content    : 

    Deleting Data Collection Rules [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ] ... Please Wait !
    Headers    : {[Pragma, System.String[]], [Request-Context, System.String[]], [x-ms-correlation-request-id, System.String[]], [x-ms-client
                 -request-id, System.String[]]...}
    Version    : 1.1
    StatusCode : 200
    Method     : DELETE
    Content    : 
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrNameLike,
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
