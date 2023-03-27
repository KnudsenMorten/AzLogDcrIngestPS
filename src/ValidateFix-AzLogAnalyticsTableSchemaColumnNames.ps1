
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
# MIIRgwYJKoZIhvcNAQcCoIIRdDCCEXACAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoNEdVr29e7D/UeVQnVtNwhib
# mguggg3jMIIG5jCCBM6gAwIBAgIQd70OA6G3CPhUqwZyENkERzANBgkqhkiG9w0B
# AQsFADBTMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEp
# MCcGA1UEAxMgR2xvYmFsU2lnbiBDb2RlIFNpZ25pbmcgUm9vdCBSNDUwHhcNMjAw
# NzI4MDAwMDAwWhcNMzAwNzI4MDAwMDAwWjBZMQswCQYDVQQGEwJCRTEZMBcGA1UE
# ChMQR2xvYmFsU2lnbiBudi1zYTEvMC0GA1UEAxMmR2xvYmFsU2lnbiBHQ0MgUjQ1
# IENvZGVTaWduaW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAwggIK
# AoICAQDWQk3540/GI/RsHYGmMPdIPc/Q5Y3lICKWB0Q1XQbPDx1wYOYmVPpTI2AC
# qF8CAveOyW49qXgFvY71TxkkmXzPERabH3tr0qN7aGV3q9ixLD/TcgYyXFusUGcs
# JU1WBjb8wWJMfX2GFpWaXVS6UNCwf6JEGenWbmw+E8KfEdRfNFtRaDFjCvhb0N66
# WV8xr4loOEA+COhTZ05jtiGO792NhUFVnhy8N9yVoMRxpx8bpUluCiBZfomjWBWX
# ACVp397CalBlTlP7a6GfGB6KDl9UXr3gW8/yDATS3gihECb3svN6LsKOlsE/zqXa
# 9FkojDdloTGWC46kdncVSYRmgiXnQwp3UrGZUUL/obLdnNLcGNnBhqlAHUGXYoa8
# qP+ix2MXBv1mejaUASCJeB+Q9HupUk5qT1QGKoCvnsdQQvplCuMB9LFurA6o44EZ
# qDjIngMohqR0p0eVfnJaKnsVahzEaeawvkAZmcvSfVVOIpwQ4KFbw7MueovE3vFL
# H4woeTBFf2wTtj0s/y1KiirsKA8tytScmIpKbVo2LC/fusviQUoIdxiIrTVhlBLz
# pHLr7jaep1EnkTz3ohrM/Ifll+FRh2npIsyDwLcPRWwH4UNP1IxKzs9jsbWkEHr5
# DQwosGs0/iFoJ2/s+PomhFt1Qs2JJnlZnWurY3FikCUNCCDx/wIDAQABo4IBrjCC
# AaowDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBIGA1UdEwEB
# /wQIMAYBAf8CAQAwHQYDVR0OBBYEFNqzjcAkkKNrd9MMoFndIWdkdgt4MB8GA1Ud
# IwQYMBaAFB8Av0aACvx4ObeltEPZVlC7zpY7MIGTBggrBgEFBQcBAQSBhjCBgzA5
# BggrBgEFBQcwAYYtaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25p
# bmdyb290cjQ1MEYGCCsGAQUFBzAChjpodHRwOi8vc2VjdXJlLmdsb2JhbHNpZ24u
# Y29tL2NhY2VydC9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3J0MEEGA1UdHwQ6MDgwNqA0
# oDKGMGh0dHA6Ly9jcmwuZ2xvYmFsc2lnbi5jb20vY29kZXNpZ25pbmdyb290cjQ1
# LmNybDBWBgNVHSAETzBNMEEGCSsGAQQBoDIBMjA0MDIGCCsGAQUFBwIBFiZodHRw
# czovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAIBgZngQwBBAEwDQYJ
# KoZIhvcNAQELBQADggIBAAiIcibGr/qsXwbAqoyQ2tCywKKX/24TMhZU/T70MBGf
# j5j5m1Ld8qIW7tl4laaafGG4BLX468v0YREz9mUltxFCi9hpbsf/lbSBQ6l+rr+C
# 1k3MEaODcWoQXhkFp+dsf1b0qFzDTgmtWWu4+X6lLrj83g7CoPuwBNQTG8cnqbmq
# LTE7z0ZMnetM7LwunPGHo384aV9BQGf2U33qQe+OPfup1BE4Rt886/bNIr0TzfDh
# 5uUzoL485HjVG8wg8jBzsCIc9oTWm1wAAuEoUkv/EktA6u6wGgYGnoTm5/DbhEb7
# c9krQrbJVzTHFsCm6yG5qg73/tvK67wXy7hn6+M+T9uplIZkVckJCsDZBHFKEUta
# ZMO8eHitTEcmZQeZ1c02YKEzU7P2eyrViUA8caWr+JlZ/eObkkvdBb0LDHgGK89T
# 2L0SmlsnhoU/kb7geIBzVN+nHWcrarauTYmAJAhScFDzAf9Eri+a4OFJCOHhW9c4
# 0Z4Kip2UJ5vKo7nb4jZq42+5WGLgNng2AfrBp4l6JlOjXLvSsuuKy2MIL/4e81Yp
# 4jWb2P/ppb1tS1ksiSwvUru1KZDaQ0e8ct282b+Awdywq7RLHVg2N2Trm+GFF5op
# ov3mCNKS/6D4fOHpp9Ewjl8mUCvHouKXd4rv2E0+JuuZQGDzPGcMtghyKTVTgTTc
# MIIG9TCCBN2gAwIBAgIMeWPZY2rjO3HZBQJuMA0GCSqGSIb3DQEBCwUAMFkxCzAJ
# BgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8wLQYDVQQDEyZH
# bG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMDAeFw0yMzAzMjcx
# MDIxMzRaFw0yNjAzMjMxNjE4MThaMGMxCzAJBgNVBAYTAkRLMRAwDgYDVQQHEwdL
# b2xkaW5nMRAwDgYDVQQKEwcybGlua0lUMRAwDgYDVQQDEwcybGlua0lUMR4wHAYJ
# KoZIhvcNAQkBFg9tb2tAMmxpbmtpdC5uZXQwggIiMA0GCSqGSIb3DQEBAQUAA4IC
# DwAwggIKAoICAQDMpI1rTOoWOSET3lSFQfsl/t83DCUEdoI02fNS5xlURPeGZNhi
# xQMKrhmFrdbIaEx01eY+hH9gF2AQ1ZDa7orCVSde1LDBnbFPLqcHWW5RWyzcy8Pq
# gV1QvzlFbmvTNHLm+wn1DZJ/1qJ+A+4uNUMrg13WRTiH0YWd6pwmAiQkoGC6FFwE
# usXotrT5JJNcPGlxBccm8su3kakI5B6iEuTeKh92EJM/km0pc/8o+pg+uR+f07Pp
# WcV9sS//JYCSLaXWicfrWq6a7/7U/vp/Wtdz+d2DcwljpsoXd++vuwzF8cUs09uJ
# KtdyrN8Z1DxqFlMdlD0ZyR401qAX4GO2XdzH363TtEBKAwvV+ReW6IeqGp5FUjnU
# j0RZ7NPOSiPr5G7d23RutjCHlGzbUr+5mQV/IHGL9LM5aNHsu22ziVqImRU9nwfq
# QVb8Q4aWD9P92hb3jNcH4bIWiQYccf9hgrMGGARx+wd/vI+AU/DfEtN9KuLJ8rNk
# LfbXRSB70le5SMP8qK09VjNXK/i6qO+Hkfh4vfNnW9JOvKdgRnQjmNEIYWjasbn8
# GyvoFVq0GOexiF/9XFKwbdGpDLJYttfcVZlBoSMPOWRe8HEKZYbJW1McjVIpWPnP
# d6tW7CBY2jp4476OeoPpMiiApuc7BhUC0VWl1Ei2PovDUoh/H3euHrWqbQIDAQAB
# o4IBsTCCAa0wDgYDVR0PAQH/BAQDAgeAMIGbBggrBgEFBQcBAQSBjjCBizBKBggr
# BgEFBQcwAoY+aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNvbS9jYWNlcnQvZ3Nn
# Y2NyNDVjb2Rlc2lnbmNhMjAyMC5jcnQwPQYIKwYBBQUHMAGGMWh0dHA6Ly9vY3Nw
# Lmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25jYTIwMjAwVgYDVR0gBE8w
# TTBBBgkrBgEEAaAyATIwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wCAYGZ4EMAQQBMAkGA1UdEwQCMAAwRQYDVR0f
# BD4wPDA6oDigNoY0aHR0cDovL2NybC5nbG9iYWxzaWduLmNvbS9nc2djY3I0NWNv
# ZGVzaWduY2EyMDIwLmNybDATBgNVHSUEDDAKBggrBgEFBQcDAzAfBgNVHSMEGDAW
# gBTas43AJJCja3fTDKBZ3SFnZHYLeDAdBgNVHQ4EFgQUMcaWNqucqymu1RTg02YU
# 3zypsskwDQYJKoZIhvcNAQELBQADggIBAHt/DYGUeCFfbtuuP5/44lpR2wbvOO49
# b6TenaL8TL3VEGe/NHh9yc3LxvH6PdbjtYgyGZLEooIgfnfEo+WL4fqF5X2BH34y
# EAsHCJVjXIjs1mGc5fajx14HU52iLiQOXEfOOk3qUC1TF3NWG+9mezho5XZkSMRo
# 0Ypg7Js2Pk3U7teZReCJFI9FSYa/BT2DnRFWVTlx7T5lIz6rKvTO1qQC2G3NKVGs
# HMtBTjsF6s2gpOzt7zF3o+DsnJukQRn0R9yTzgrx9nXYiHz6ti3HuJ4U7i7ILpgS
# RNrzmpVXXSH0wYxPT6TLm9eZR8qdZn1tGSb1zoIT70arnzE90oz0x7ej1fC8IUA/
# AYhkmfa6feI7OMU5xnsUjhSiyzMVhD06+RD3t5JrbKRoCgqixGb7DGM+yZVjbmhw
# cvr3UGVld9++pbsFeCB3xk/tcMXtBPdHTESPvUjSCpFbyldxVLU6GVIdzaeHAiBy
# S0NXrJVxcyCWusK41bJ1jP9zsnnaUCRERjWF5VZsXYBhY62NSOlFiCNGNYmVt7fi
# b4V6LFGoWvIv2EsWgx/uR/ypWndjmV6uBIN/UMZAhC25iZklNLFGDZ5dCUxLuoyW
# PVCTBYpM3+bN6dmbincjG0YDeRjTVfPN5niP1+SlRwSQxtXqYoDHq+3xVzFWVBqC
# NdoiM/4DqJUBMYIDCjCCAwYCAQEwaTBZMQswCQYDVQQGEwJCRTEZMBcGA1UEChMQ
# R2xvYmFsU2lnbiBudi1zYTEvMC0GA1UEAxMmR2xvYmFsU2lnbiBHQ0MgUjQ1IENv
# ZGVTaWduaW5nIENBIDIwMjACDHlj2WNq4ztx2QUCbjAJBgUrDgMCGgUAoHgwGAYK
# KwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIB
# BDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQU
# xhhvYIf+85ieVBVh6XPEJrXactgwDQYJKoZIhvcNAQEBBQAEggIAZGhA9f3/iYJu
# QI6f3m6HPuZMiHr5wB2T+LEohtvL13XCSjY0uwDHMGDFpLwNA4AeJl2HUjyIwNFW
# xlc8N01ADext2Z+mPzqgh/wtHAw5LJzG9x0XCyXTtrOomx5fSwXYXX1sBp5Xr7g2
# c/+N6XGwD1bX9R//ZL4V6OOISJGuX3vbbSsu+MBm8tIVPXf2k+seqDkUmHaLZiB0
# izzPaIWGhbXNYHmD0cBT3zCab1IkJ1DGYnhb7d/HFc8WJxXFdH14pL37wLRhmd+f
# UJCRcOtmlFnUMXCJ0pbuwTkICMztiLUwo4REVLl30soJlp3CjeWvH1wwyiivHEoN
# EjPBXJFD2VBVjeBYS7iYWG51GoqFWjIj+AV3sXh0AmGYJyBHOik+yVxdNGv3KJkp
# /UWcqxd03gIfdhp9rl877Gm2SU4+LpNFDwPu18WJvv8B0XYN2284awPsP+gja5Cj
# LhhgSxXCrkN+3ylD1W8Zo5g8HnDpPWZT9GBoPgfzFTS0ZK6HB5GOq1QfZLEdmdPq
# zdrsm/aAlJusS+PkWiOOBjbi4a9XO8p3FckjmhSKvzvVncmf0U+X55h4Vpk28X/c
# T68Y2ozMky6sTY8wk3BypbyFtpMx4eLE/owFDlnlosUv/OpB4qZbzSJHCj2Qtd7Q
# DnpPexQae330G5lxnWrr2NE0lfyxAUw=
# SIG # End signature block
