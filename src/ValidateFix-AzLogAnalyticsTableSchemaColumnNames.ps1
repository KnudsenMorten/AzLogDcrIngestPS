
Function ValidateFix-AzLogAnalyticsTableSchemaColumnNames
{
 <#
    .SYNOPSIS
    Validates the column names in the schema are valid according the requirement for LogAnalytics tables
    Fixes any issues by rebuild the source object

    .DESCRIPTION
    Checks for prohibited column names - and adds new column with <name>_ - and removes prohibited column name
    Checks for column name length is under 45 characters
    Checks for column names must not start with _ (underscore) - or contain " " (space) or . (period)
    In case of issues, an new source object is build

    .PARAMETER Data
    This is the data array

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated $DataVariable with valid column names

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
    $Verbose                   = $true  # $true or $false

    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------
    $DNSName                   = (Get-CimInstance win32_computersystem).DNSHostName +"." + (Get-CimInstance win32_computersystem).Domain
    $ComputerName              = (Get-CimInstance win32_computersystem).DNSHostName
    [datetime]$CollectionTime  = ( Get-date ([datetime]::Now.ToUniversalTime()) -format "yyyy-MM-ddTHH:mm:ssK" )

    $UserLoggedOnRaw           = Get-Process -IncludeUserName -Name explorer | Select-Object UserName -Unique
    $UserLoggedOn              = $UserLoggedOnRaw.UserName

    Write-Output "Get-Process is pretty slow .... take a cup coffee :-)"
    $DataVariable = Get-Process

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------
    # convert CIM array to PSCustomObject and remove CIM class information
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose
    
    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose

    # add Computer & UserLoggedOn info to existing array
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name UserLoggedOn -Column2Data $UserLoggedOn -Verbose:$Verbose

    # adding prohibted columns to data - to demonstrate how it works
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name "Type" -Column1Data "MyDataType" -Verbose:$Verbose
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name "Id" -Column1Data "MyId" -Verbose:$Verbose

    # schema - before changes - we see columns named Type and Id (prohibited)
    Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose

    # Data before changes - we see columns named Type and Id (prohibited)
    $DataVariable[0]

    # Validating/fixing schema data structure of source data
    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$verbose

    # schema - after changes - we see data was transferred to new columns (type_ and id_ - and the wrong columns (type, id) were removed
    Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose

    # Data after changes - we see data was transferred to new columns (type_ and id_ - and the wrong columns (type, id) were removed
    $DataVariable[0]

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Converting CIM array to Object & removing CIM class data in array .... please wait !
    VERBOSE:   Adding CollectionTime to all entries in array .... please wait !
    VERBOSE:   Adding columns to all entries in array .... please wait !
    VERBOSE:   Adding columns to all entries in array .... please wait !
    VERBOSE:   Adding columns to all entries in array .... please wait !

    VERBOSE:   Validating schema structure of source data ... Please Wait !
    VERBOSE:   ISSUE - Column name is prohibited [ Id ]
    VERBOSE:   ISSUE - Column name is prohibited [ Type ]
    VERBOSE:   ISSUE - Column name must start with character [ __NounName ]
    VERBOSE:   ISSUE - Column name is prohibited [ Id ]
    VERBOSE:   ISSUE - Column name is prohibited [ Type ]
    VERBOSE:   ISSUE - Column name must start with character [ __NounName ]
    VERBOSE:   Issues found .... fixing schema structure of source data ... Please Wait !

    name                       type      
    ----                       ----      
    BasePriority               int       
    CollectionTime             datetime  
    Company                    dynamic   
    Computer                   string    
    Container                  dynamic   
    CPU                        dynamic   
    Description                dynamic   
    EnableRaisingEvents        boolean   
    ExitCode                   dynamic   
    ExitTime                   dynamic   
    FileVersion                dynamic   
    Handle                     int       
    HandleCount                int       
    Handles                    int       
    HasExited                  boolean   
    Id                         string    
    MachineName                string    
    MainModule                 dynamic   
    MainWindowHandle           int       
    MainWindowTitle            string    
    MaxWorkingSet              int       
    MinWorkingSet              int       
    Modules                    dynamic   
    Name                       string    
    NonpagedSystemMemorySize   int       
    NonpagedSystemMemorySize64 int       
    NPM                        int       
    PagedMemorySize            int       
    PagedMemorySize64          int       
    PagedSystemMemorySize      int       
    PagedSystemMemorySize64    int       
    Path                       string    
    PeakPagedMemorySize        int       
    PeakPagedMemorySize64      int       
    PeakVirtualMemorySize      int       
    PeakVirtualMemorySize64    int       
    PeakWorkingSet             int       
    PeakWorkingSet64           int       
    PM                         int       
    PriorityBoostEnabled       boolean   
    PriorityClass              int       
    PrivateMemorySize          int       
    PrivateMemorySize64        int       
    PrivilegedProcessorTime    dynamic   
    ProcessName                string    
    ProcessorAffinity          int       
    Product                    dynamic   
    ProductVersion             dynamic   
    Responding                 boolean   
    SafeHandle                 dynamic   
    SessionId                  int       
    SI                         int       
    Site                       dynamic   
    StandardError              dynamic   
    StandardInput              dynamic   
    StandardOutput             dynamic   
    StartInfo                  dynamic   
    StartTime                  datetime  
    SynchronizingObject        dynamic   
    Threads                    dynamic   
    TotalProcessorTime         dynamic   
    Type                       string    
    UserLoggedOn               string    
    UserProcessorTime          dynamic   
    VirtualMemorySize          int       
    VirtualMemorySize64        int       
    VM                         int       
    WorkingSet                 int       
    WorkingSet64               int       
    WS                         int       
    __NounName                 string    
    AcrobatNotificationClient  MyDataType


    BasePriority               : 8
    CollectionTime             : 12-03-2023 17:10:15
    Company                    : 
    Computer                   : STRV-MOK-DT-02
    Container                  : 
    CPU                        : 0,015625
    Description                : 
    EnableRaisingEvents        : False
    ExitCode                   : 
    ExitTime                   : 
    FileVersion                : 
    Handle                     : 10044
    HandleCount                : 377
    Handles                    : 377
    HasExited                  : False
    Id_                        : MyId
    MachineName                : .
    MainModule                 : @{ModuleName=AcrobatNotificationClient.exe; FileName=C:\Program Files\WindowsApps\AcrobatNotificationClient_
                                 1.0.4.0_x86__e1rzdqpraam7r\AcrobatNotificationClient.exe; BaseAddress=6225920; ModuleMemorySize=438272; Entr
                                 yPointAddress=6460140; FileVersionInfo=; Site=; Container=}
    MainWindowHandle           : 0
    MainWindowTitle            : 
    MaxWorkingSet              : 1413120
    MinWorkingSet              : 204800
    Modules                    : {@{ModuleName=AcrobatNotificationClient.exe; FileName=C:\Program Files\WindowsApps\AcrobatNotificationClient
                                 _1.0.4.0_x86__e1rzdqpraam7r\AcrobatNotificationClient.exe; BaseAddress=6225920; ModuleMemorySize=438272; Ent
                                 ryPointAddress=6460140; FileVersionInfo=; Site=; Container=}, @{ModuleName=ntdll.dll; FileName=C:\WINDOWS\SY
                                 STEM32\ntdll.dll; BaseAddress=140715251924992; ModuleMemorySize=2179072; EntryPointAddress=0; FileVersionInf
                                 o=; Site=; Container=}, @{ModuleName=wow64.dll; FileName=C:\WINDOWS\System32\wow64.dll; BaseAddress=14071524
                                 5764608; ModuleMemorySize=356352; EntryPointAddress=140715245870880; FileVersionInfo=; Site=; Container=}, @
                                 {ModuleName=wow64base.dll; FileName=C:\WINDOWS\System32\wow64base.dll; BaseAddress=140715221450752; ModuleMe
                                 morySize=36864; EntryPointAddress=140715221454864; FileVersionInfo=; Site=; Container=}...}
    Name                       : AcrobatNotificationClient
    NonpagedSystemMemorySize   : 23424
    NonpagedSystemMemorySize64 : 23424
    NPM                        : 23424
    PagedMemorySize            : 10592256
    PagedMemorySize64          : 10592256
    PagedSystemMemorySize      : 466384
    PagedSystemMemorySize64    : 466384
    Path                       : C:\Program Files\WindowsApps\AcrobatNotificationClient_1.0.4.0_x86__e1rzdqpraam7r\AcrobatNotificationClient.
                                 exe
    PeakPagedMemorySize        : 11440128
    PeakPagedMemorySize64      : 11440128
    PeakVirtualMemorySize      : 318820352
    PeakVirtualMemorySize64    : 318820352
    PeakWorkingSet             : 39202816
    PeakWorkingSet64           : 39202816
    PM                         : 10592256
    PriorityBoostEnabled       : True
    PriorityClass              : 32
    PrivateMemorySize          : 10592256
    PrivateMemorySize64        : 10592256
    PrivilegedProcessorTime    : @{Ticks=156250; Days=0; Hours=0; Milliseconds=15; Minutes=0; Seconds=0; TotalDays=1,80844907407407E-07; Tota
                                 lHours=4,34027777777778E-06; TotalMilliseconds=15,625; TotalMinutes=0,00026041666666666666; TotalSeconds=0,0
                                 15625}
    ProcessName                : AcrobatNotificationClient
    ProcessorAffinity          : 65535
    Product                    : 
    ProductVersion             : 
    Responding                 : True
    SafeHandle                 : @{IsInvalid=False; IsClosed=False}
    SessionId                  : 1
    SI                         : 1
    Site                       : 
    StandardError              : 
    StandardInput              : 
    StandardOutput             : 
    StartInfo                  : @{Verb=; Arguments=; CreateNoWindow=False; EnvironmentVariables=System.Object[]; Environment=System.Object[]
                                 ; RedirectStandardInput=False; RedirectStandardOutput=False; RedirectStandardError=False; StandardErrorEncod
                                 ing=; StandardOutputEncoding=; UseShellExecute=True; Verbs=System.Object[]; UserName=; Password=; PasswordIn
                                 ClearText=; Domain=; LoadUserProfile=False; FileName=; WorkingDirectory=; ErrorDialog=False; ErrorDialogPare
                                 ntHandle=0; WindowStyle=0}
    StartTime                  : 08-03-2023 22:22:46
    SynchronizingObject        : 
    Threads                    : {@{BasePriority=8; CurrentPriority=8; Id=24524; PriorityBoostEnabled=True; PriorityLevel=0; PrivilegedProces
                                 sorTime=; StartAddress=140715252309904; StartTime=08-03-2023 22:22:46; ThreadState=5; TotalProcessorTime=; U
                                 serProcessorTime=; WaitReason=5; Site=; Container=}, @{BasePriority=8; CurrentPriority=9; Id=18836; Priority
                                 BoostEnabled=True; PriorityLevel=0; PrivilegedProcessorTime=; StartAddress=140715252309904; StartTime=08-03-
                                 2023 22:22:46; ThreadState=5; TotalProcessorTime=; UserProcessorTime=; WaitReason=5; Site=; Container=}, @{B
                                 asePriority=8; CurrentPriority=8; Id=18608; PriorityBoostEnabled=True; PriorityLevel=0; PrivilegedProcessorT
                                 ime=; StartAddress=140715252309904; StartTime=08-03-2023 22:22:46; ThreadState=5; TotalProcessorTime=; UserP
                                 rocessorTime=; WaitReason=5; Site=; Container=}, @{BasePriority=8; CurrentPriority=9; Id=18832; PriorityBoos
                                 tEnabled=True; PriorityLevel=0; PrivilegedProcessorTime=; StartAddress=140715252309904; StartTime=08-03-2023
                                  22:22:46; ThreadState=5; TotalProcessorTime=; UserProcessorTime=; WaitReason=5; Site=; Container=}...}
    TotalProcessorTime         : @{Ticks=156250; Days=0; Hours=0; Milliseconds=15; Minutes=0; Seconds=0; TotalDays=1,80844907407407E-07; Tota
                                 lHours=4,34027777777778E-06; TotalMilliseconds=15,625; TotalMinutes=0,00026041666666666666; TotalSeconds=0,0
                                 15625}
    Type_                      : MyDataType
    UserLoggedOn               : 2LINKIT\mok
    UserProcessorTime          : @{Ticks=0; Days=0; Hours=0; Milliseconds=0; Minutes=0; Seconds=0; TotalDays=0; TotalHours=0; TotalMillisecon
                                 ds=0; TotalMinutes=0; TotalSeconds=0}
    VirtualMemorySize          : 289554432
    VirtualMemorySize64        : 289554432
    VM                         : 289554432
    WorkingSet                 : 6762496
    WorkingSet64               : 6762496
    WS                         : 6762496
    NounName                   : 
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data
         )

    $ProhibitedColumnNames = @("_ResourceId","id","_ResourceId","_SubscriptionId","TenantId","Type","UniqueId","Title","Date")

    Write-Verbose "  Validating schema structure of source data ... Please Wait !"

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

                        If ($ColumnName -in $ProhibitedColumnNames)   # prohibited column names
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name is prohibited [ $($ColumnName) ]"
                            }

                        ElseIf ($ColumnName -like "_*")   # remove any leading underscores - column in DCR/LA must start with a character
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name must start with character [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "*-*")   # includes - (hyphen)
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name include - (hyphen) - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "*:*")   # includes : (semicolon)
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name include : (semicolon) - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "*.*")   # includes . (period)
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name include . (period) - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName -like "* *")   # includes whitespace " "
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column name include whitespace - must be removed [ $($ColumnName) ]"
                            }
                        ElseIf ($ColumnName.Length -gt 45)   # trim the length to maximum 45 characters
                            {
                                $IssuesFound = $true
                                Write-Verbose "  ISSUE - Column length is greater than 45 characters (trimming column name is neccessary)  [ $($ColumnName) ]"
                            }
                    }
            }

    If ($IssuesFound)
        {
            Write-Verbose "  Issues found .... fixing schema structure of source data ... Please Wait !"

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
                            ElseIf ($ColumnName -like "*:*")   # remove any : (semicolon)
                                {
                                    $UpdColumn = $ColumnName.Replace(":","")
                                    $ColumnData = $Entry.$Column
                                    $_ | Add-Member -MemberType NoteProperty -Name $UpdColumn -Value $ColumnData -Force
                                    $_.PSObject.Properties.Remove($ColumnName)
                                }
                            ElseIf ($ColumnName -like "*-*")   # remove any - (hyphen)
                                {
                                    $UpdColumn = $ColumnName.Replace("-","")
                                    $ColumnData = $Entry.$Column
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
                Write-Progress -Activity "Validating/fixing schema structure of source object" -Status "Ready" -Completed
            }
        }
    Else
        {
            Write-Verbose "  SUCCESS - No issues found in schema structure"
        }
    Return [array]$Data
}

# SIG # Begin signature block
# MIIXAgYJKoZIhvcNAQcCoIIW8zCCFu8CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOYupR1lh+NQDAgw2F+/lx9K7
# OAigghNiMIIFojCCBIqgAwIBAgIQeAMYQkVwikHPbwG47rSpVDANBgkqhkiG9w0B
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
# BgkqhkiG9w0BCQQxFgQUb2ylAo4o3FH0cnSUz6cDS6ThriYwDQYJKoZIhvcNAQEB
# BQAEggIAf+yluv0vLh1kTL2fBVPcLCzt53ywlKPPYb1lTF3IDMAVigXpE9ZRMZPU
# /O3RVUj4qCRC6nrJvN0SG0+l9dnWdVBt/1TVPLWtMHUG8J9OAxnnXK6+eBu3UxQM
# LVKwZmvB2rGgp9q+ty8dHEbVZhhJuM/P1C1sJS1pZUPbVkbxKGj9g4ZsvIUyumbG
# 1H9TMPYieDa99bjWPHgJsAbW/16pN7nbhzYhpl546zxSlObjFSenoUYB6S8MKSiI
# FG08QQqfwiO7gTigZV7pPGvqKTZhI5tpEwozyoDqLFIpXAvOgMh79Etkk4MfdRWa
# UuX7J/cTrN4Au4UfWTeJgQlN59yLASf4nH6h4+wVY24QNFJ5aDFSeUEltcnyW2yX
# STxRBxiBu1xECWK9I9rRQgW7/Of3v6o5sNHrCLxFiwga6maLf+obu4glI/y3mR0C
# +b/tpmRdSaUI6LYGaLAGdjcFJtwC7F2OOI/a+QIczVWfDrq5WXm5MYA0jD+Daj/Y
# MWAxe8mJyNLG4E5AJxglgZ7okONceH2Q1mUqUd3jRUbblhaH12B03kAol3KCCB+O
# NJg4kDAxRGU5jAOryf3NjB+ozSifyWwxefHaEoIKeGW84eUP0OU9JoR/zgFgrtbq
# L3rIzgKOXN4HDX1PMeEeec+xIRJbVac71n/Ria1eeIDqCaMaGSE=
# SIG # End signature block
