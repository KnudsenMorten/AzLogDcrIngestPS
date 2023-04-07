Function Add-CollectionTimeToAllEntriesInArray
{
  <#
    .SYNOPSIS
    Add property CollectionTime (based on current time) to all entries on the object

    .DESCRIPTION
    Gives capability to do proper searching in queries to find latest set of records with same collection time
    Time Generated cannot be used when you are sending data in batches, as TimeGenerated will change
    An example where this is important is a complete list of applications for a computer. We want all applications to
    show up when queriying for the latest data

    .PARAMETER Data
    Object to modify

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

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

    $DataVariable = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExcludeProperty "CIM*"

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose
    $DataVariable

    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose
    $DataVariable

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------

    VERBOSE:   Adding CollectionTime to all entries in array .... please wait !
    Caption                                 : Intel64 Family 6 Model 165 Stepping 5
    Description                             : Intel64 Family 6 Model 165 Stepping 5
    InstallDate                             : 
    Name                                    : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
    Status                                  : OK
    Availability                            : 3
    ConfigManagerErrorCode                  : 
    ConfigManagerUserConfig                 : 
    CreationClassName                       : Win32_Processor
    DeviceID                                : CPU0
    ErrorCleared                            : 
    ErrorDescription                        : 
    LastErrorCode                           : 
    PNPDeviceID                             : 
    PowerManagementCapabilities             : 
    PowerManagementSupported                : False
    StatusInfo                              : 3
    SystemCreationClassName                 : Win32_ComputerSystem
    SystemName                              : STRV-MOK-DT-02
    AddressWidth                            : 64
    CurrentClockSpeed                       : 2904
    DataWidth                               : 64
    Family                                  : 198
    LoadPercentage                          : 1
    MaxClockSpeed                           : 2904
    OtherFamilyDescription                  : 
    Role                                    : CPU
    Stepping                                : 
    UniqueId                                : 
    UpgradeMethod                           : 1
    Architecture                            : 9
    AssetTag                                : To Be Filled By O.E.M.
    Characteristics                         : 252
    CpuStatus                               : 1
    CurrentVoltage                          : 8
    ExtClock                                : 100
    L2CacheSize                             : 2048
    L2CacheSpeed                            : 
    L3CacheSize                             : 16384
    L3CacheSpeed                            : 0
    Level                                   : 6
    Manufacturer                            : GenuineIntel
    NumberOfCores                           : 8
    NumberOfEnabledCore                     : 8
    NumberOfLogicalProcessors               : 16
    PartNumber                              : To Be Filled By O.E.M.
    ProcessorId                             : BFEBFBFF000A0655
    ProcessorType                           : 3
    Revision                                : 
    SecondLevelAddressTranslationExtensions : False
    SerialNumber                            : To Be Filled By O.E.M.
    SocketDesignation                       : U3E1
    ThreadCount                             : 16
    Version                                 : 
    VirtualizationFirmwareEnabled           : False
    VMMonitorModeExtensions                 : False
    VoltageCaps                             : 
    PSComputerName                          : 
    CollectionTime                          : 12-03-2023 16:08:33
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data
         )

    [datetime]$CollectionTime = ( Get-date ([datetime]::Now.ToUniversalTime()) -format "yyyy-MM-ddTHH:mm:ssK" )

    Write-Verbose "  Adding CollectionTime to all entries in array .... please wait !"

    $IntermediateObj = @()
    ForEach ($Entry in $Data)
        {
            $Entry | Add-Member -MemberType NoteProperty -Name CollectionTime -Value $CollectionTime -Force | Out-Null

            $IntermediateObj += $Entry
        }

    return [array]$IntermediateObj
}


Function Add-ColumnDataToAllEntriesInArray
{
  <#
    .SYNOPSIS
    Adds up to 3 extra columns and data to the object

    .DESCRIPTION
    Gives capability to extend the data with for example Computer and UserLoggedOn, which are nice data to have in the inventory

    .PARAMETER Data
    Object to modify

    .PARAMETER Column1Name
    Name of the column to add (for example Computer)

    .PARAMETER Column1Data
    Data to add to the column1 (for example $Env:Computer)

    .PARAMETER Column2Name
    Name of the column to add (for example UserLoggedOn)

    .PARAMETER Column2Data
    Data to add to the column1 (for example $UserLoggedOn)

    .PARAMETER Column3Name
    Name of the column to add (for example ComputerType)

    .PARAMETER Column3Data
    Data to add to the column1 (for example $ComputerType)

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

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

    $DataVariable = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExcludeProperty "CIM*"
    $DataVariable

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose
    $DataVariable

    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose
    $DataVariable

    # add Computer & UserLoggedOn info to existing array
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $ComputerName  -Column2Name UserLoggedOn -Column2Data $UserLoggedOn -Verbose:$verbose
    $DataVariable

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    Caption                                 : Intel64 Family 6 Model 165 Stepping 5
    Description                             : Intel64 Family 6 Model 165 Stepping 5
    InstallDate                             : 
    Name                                    : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
    Status                                  : OK
    Availability                            : 3
    ConfigManagerErrorCode                  : 
    ConfigManagerUserConfig                 : 
    CreationClassName                       : Win32_Processor
    DeviceID                                : CPU0
    ErrorCleared                            : 
    ErrorDescription                        : 
    LastErrorCode                           : 
    PNPDeviceID                             : 
    PowerManagementCapabilities             : 
    PowerManagementSupported                : False
    StatusInfo                              : 3
    SystemCreationClassName                 : Win32_ComputerSystem
    SystemName                              : STRV-MOK-DT-02
    AddressWidth                            : 64
    CurrentClockSpeed                       : 2904
    DataWidth                               : 64
    Family                                  : 198
    LoadPercentage                          : 1
    MaxClockSpeed                           : 2904
    OtherFamilyDescription                  : 
    Role                                    : CPU
    Stepping                                : 
    UniqueId                                : 
    UpgradeMethod                           : 1
    Architecture                            : 9
    AssetTag                                : To Be Filled By O.E.M.
    Characteristics                         : 252
    CpuStatus                               : 1
    CurrentVoltage                          : 8
    ExtClock                                : 100
    L2CacheSize                             : 2048
    L2CacheSpeed                            : 
    L3CacheSize                             : 16384
    L3CacheSpeed                            : 0
    Level                                   : 6
    Manufacturer                            : GenuineIntel
    NumberOfCores                           : 8
    NumberOfEnabledCore                     : 8
    NumberOfLogicalProcessors               : 16
    PartNumber                              : To Be Filled By O.E.M.
    ProcessorId                             : BFEBFBFF000A0655
    ProcessorType                           : 3
    Revision                                : 
    SecondLevelAddressTranslationExtensions : False
    SerialNumber                            : To Be Filled By O.E.M.
    SocketDesignation                       : U3E1
    ThreadCount                             : 16
    Version                                 : 
    VirtualizationFirmwareEnabled           : False
    VMMonitorModeExtensions                 : False
    VoltageCaps                             : 
    PSComputerName                          : 
    CollectionTime                          : 12-03-2023 16:19:12
    Computer                                : STRV-MOK-DT-02
    UserLoggedOn                            : 2LINKIT\mok#>
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [string]$Column1Name,
            [Parameter(mandatory)]
                [string]$Column1Data,
            [Parameter()]
                [string]$Column2Name,
            [Parameter()]
                [string]$Column2Data,
            [Parameter()]
                [string]$Column3Name,
            [Parameter()]
                [string]$Column3Data
         )

    Write-Verbose "  Adding columns to all entries in array .... please wait !"
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
    return [array]$IntermediateObj
}


Function Build-DataArrayToAlignWithSchema
{
 <#
    .SYNOPSIS
    Rebuilds the source object to match modified schema structure - used after usage of ValidateFix-AzLogAnalyticsTableSchemaColumnNames

    .DESCRIPTION
    Builds new PSCustomObject object

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
    Get-ObjectSchemaAsArray -Data $DataVariable

    # Data before changes - we see columns named Type and Id (prohibited)
    $DataVariable[0]

    # Validating/fixing schema data structure of source data
    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

    # schema - after changes - we see columns named Type has been renamed to Type_ and Id to Id_ (prohibited)
    Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose

    # Data after changes - we see data was transferred to new columns (type_ and id_ - and the wrong columns (type, id) were removed
    $DataVariable[0]

    # Aligning data structure with schema (requirement for DCR)
    $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
    $DataVariable[0]

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Aligning source object structure with schema ... Please Wait !

    BasePriority               : 8
    CollectionTime             : 12-03-2023 16:25:37
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
    NounName                   : 
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
    WorkingSet                 : 6758400
    WorkingSet64               : 6758400
    WS                         : 6758400
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data
         )

    Write-Verbose "  Aligning source object structure with schema ... Please Wait !"
    
    # Get schema
    $Schema = Get-ObjectSchemaAsArray -Data $Data -Verbose:$Verbose

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
                
                Write-Progress -Activity "Aligning source object structure with schema" -Status "Ready" -Completed
                # return data from temporary array to original $Data
                $Data = $DataVariableQA
            }
        Return $Data
}


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
    It will overwrite existing schema in DCR/table – based on source object schema
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
            [Parameter(mandatory)]
                [string]$LogIngestServicePricipleObjectId,
            [Parameter(mandatory)]
                [boolean]$AzDcrSetLogIngestApiAppPermissionsDcrLevel,
            [Parameter(mandatory)]
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

        If ($EnableUploadViaLogHub -eq $false)
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


Function Convert-CimArrayToObjectFixStructure
{
  <#
    .SYNOPSIS
    Converts CIM array and remove CIM class information

    .DESCRIPTION
    Used to remove "noice" information of columns which we shouldn't send into the logs

    .PARAMETER Data
    Specifies the data object to modify

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Modified array

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

    $DataVariable = Get-CimInstance -ClassName Win32_Processor | Select-Object -ExcludeProperty "CIM*"

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose
    $DataVariable

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------

    VERBOSE:   Converting CIM array to Object & removing CIM class data in array .... please wait !
    Caption                                 : Intel64 Family 6 Model 165 Stepping 5
    Description                             : Intel64 Family 6 Model 165 Stepping 5
    InstallDate                             : 
    Name                                    : Intel(R) Core(TM) i7-10700 CPU @ 2.90GHz
    Status                                  : OK
    Availability                            : 3
    ConfigManagerErrorCode                  : 
    ConfigManagerUserConfig                 : 
    CreationClassName                       : Win32_Processor
    DeviceID                                : CPU0
    ErrorCleared                            : 
    ErrorDescription                        : 
    LastErrorCode                           : 
    PNPDeviceID                             : 
    PowerManagementCapabilities             : 
    PowerManagementSupported                : False
    StatusInfo                              : 3
    SystemCreationClassName                 : Win32_ComputerSystem
    SystemName                              : STRV-MOK-DT-02
    AddressWidth                            : 64
    CurrentClockSpeed                       : 2904
    DataWidth                               : 64
    Family                                  : 198
    LoadPercentage                          : 1
    MaxClockSpeed                           : 2904
    OtherFamilyDescription                  : 
    Role                                    : CPU
    Stepping                                : 
    UniqueId                                : 
    UpgradeMethod                           : 1
    Architecture                            : 9
    AssetTag                                : To Be Filled By O.E.M.
    Characteristics                         : 252
    CpuStatus                               : 1
    CurrentVoltage                          : 8
    ExtClock                                : 100
    L2CacheSize                             : 2048
    L2CacheSpeed                            : 
    L3CacheSize                             : 16384
    L3CacheSpeed                            : 0
    Level                                   : 6
    Manufacturer                            : GenuineIntel
    NumberOfCores                           : 8
    NumberOfEnabledCore                     : 8
    NumberOfLogicalProcessors               : 16
    PartNumber                              : To Be Filled By O.E.M.
    ProcessorId                             : BFEBFBFF000A0655
    ProcessorType                           : 3
    Revision                                : 
    SecondLevelAddressTranslationExtensions : False
    SerialNumber                            : To Be Filled By O.E.M.
    SocketDesignation                       : U3E1
    ThreadCount                             : 16
    Version                                 : 
    VirtualizationFirmwareEnabled           : False
    VMMonitorModeExtensions                 : False
    VoltageCaps                             : 
    PSComputerName                          : 
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data
         )

    Write-Verbose "  Converting CIM array to Object & removing CIM class data in array .... please wait !"

    # remove CIM info columns from object
    $Object = $Data | Select-Object -Property * -ExcludeProperty CimClass, CimInstanceProperties, CimSystemProperties

    # Convert from array to object
    $ObjectModified = $Object | ConvertTo-Json -Depth 20 | ConvertFrom-Json 

    return $ObjectModified
}


Function Convert-PSArrayToObjectFixStructure
{
  <#
    .SYNOPSIS
    Converts PS array and remove PS class information

    .DESCRIPTION
    Used to remove "noice" information of columns which we shouldn't send into the logs


    .PARAMETER Data
    Specifies the data object to modify

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Modified array

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Collecting data (in)
    #-------------------------------------------------------------------------------------------

    $verbose                                         = $true

    Write-Output ""
    Write-Output "Collecting installed applications information via registry ... Please Wait !"

    $UninstallValuesX86 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue
    $UninstallValuesX64 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* -ErrorAction SilentlyContinue

    $DataVariable       = $UninstallValuesX86
    $DataVariable      += $UninstallValuesX64

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

    # removing apps without DisplayName fx KBs
    $DataVariable = $DataVariable | Where-Object { $_.DisplayName -ne $null }
    
    # We see lots of "noice", which we don't want in our logs - PSPath, PSParentPath, PSChildname, PSDrive, PSProvider
    $DataVariable[0]

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    AuthorizedCDFPrefix  : 
    Comments             : 
    Contact              : 
    DisplayVersion       : 8.8.34.31
    HelpLink             : 
    HelpTelephone        : 
    InstallDate          : 20221101
    InstallLocation      : C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\
    InstallSource        : C:\Users\MOK~1.2LI\AppData\Local\Temp\{F09BB9BD-4825-4C23-B08A-4F622CB57050}\
    ModifyPath           : "C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\setup.exe" -
                           runfromtemp -l0x0409 
    NoModify             : 1
    Publisher            : HP Inc.
    Readme               : 
    Size                 : 
    EstimatedSize        : 54156
    SystemComponent      : 0
    UninstallString      : "C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\setup.exe" -
                           runfromtemp -l0x0409  -removeonly
    URLInfoAbout         : http://www.hp.com
    URLUpdateInfo        : 
    VersionMajor         : 8
    VersionMinor         : 8
    WindowsInstaller     : 1
    Version              : 134742050
    Language             : 1033
    DisplayName          : HP Support Assistant
    LogFile              : C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\Setup.ilg
    DisplayIcon          : C:\WINDOWS\Installer\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\ARPPRODUCTICON.exe
    RegOwner             : mok
    RegCompany           : 
    NoRepair             : 1
    QuietUninstallString : C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\UninstallHPSA.exe -s
    PSPath               : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Unins
                           tall\{54ECA61C-83AE-4EE3-A9F7-848155A33386}
    PSParentPath         : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Unins
                           tall
    PSChildName          : {54ECA61C-83AE-4EE3-A9F7-848155A33386}
    PSDrive              : HKLM
    PSProvider           : Microsoft.PowerShell.Core\Registry

    # convert PS object and remove PS class information
    $DataVariable = Convert-PSArrayToObjectFixStructure -Data $DataVariable -Verbose:$Verbose

    # Now we have removed the "noice" from all objects
    $DataVariable[0]

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    AuthorizedCDFPrefix  : 
    Comments             : 
    Contact              : 
    DisplayVersion       : 8.8.34.31
    HelpLink             : 
    HelpTelephone        : 
    InstallDate          : 20221101
    InstallLocation      : C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\
    InstallSource        : C:\Users\MOK~1.2LI\AppData\Local\Temp\{F09BB9BD-4825-4C23-B08A-4F622CB57050}\
    ModifyPath           : "C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\setup.exe" -
                           runfromtemp -l0x0409 
    NoModify             : 1
    Publisher            : HP Inc.
    Readme               : 
    Size                 : 
    EstimatedSize        : 54156
    SystemComponent      : 0
    UninstallString      : "C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\setup.exe" -
                           runfromtemp -l0x0409  -removeonly
    URLInfoAbout         : http://www.hp.com
    URLUpdateInfo        : 
    VersionMajor         : 8
    VersionMinor         : 8
    WindowsInstaller     : 1
    Version              : 134742050
    Language             : 1033
    DisplayName          : HP Support Assistant
    LogFile              : C:\Program Files (x86)\InstallShield Installation Information\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\Setup.ilg
    DisplayIcon          : C:\WINDOWS\Installer\{54ECA61C-83AE-4EE3-A9F7-848155A33386}\ARPPRODUCTICON.exe
    RegOwner             : mok
    RegCompany           : 
    NoRepair             : 1
    QuietUninstallString : C:\Program Files (x86)\Hewlett-Packard\HP Support Framework\UninstallHPSA.exe -s
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data
         )

    Write-Verbose "  Converting PS array to Object & removing PS class data in array .... please wait !"

    # remove CIM info columns from object
    $Object = $Data | Select-Object -Property * -ExcludeProperty PSPath, PSProvider, PSParentPath, PSDrive, PSChildName, PSSnapIn

    # Convert from array to object
    $ObjectModified = $Object | ConvertTo-Json -Depth 10 | ConvertFrom-Json 

    return $ObjectModified
}


Function CreateUpdate-AzDataCollectionRuleLogIngestCustomLog
{
 <#
    .SYNOPSIS
    Create or Update Azure Data Collection Rule (DCR) used for log ingestion to Azure LogAnalytics using Log Ingestion API

    .DESCRIPTION
    Uses schema based on source object

    .AUTHOR
    Morten Knudsen, Microsoft MVP - https://mortenknudsen.net

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER SchemaSourceObject
    This is the schema in hash table format coming from the source object

    .PARAMETER SchemaMode
    SchemaMode = Merge (default)
    It will do a merge/union of new properties and existing schema properties. DCR will import schema from table

    SchemaMode = Overwrite
    It will overwrite existing schema in DCR/table – based on source object schema
    This parameter can be useful for separate overflow work

    .PARAMETER AzLogWorkspaceResourceId
    This is the Loganaytics Resource Id

    .PARAMETER DceName
    This is name of the Data Collection Endpoint to use for the upload
    Function will automatically look check in a global variable ($global:AzDceDetails) - or do a query using Azure Resource Graph to find DCE with name
    Goal is to find the log ingestion Uri on the DCE

    Variable $global:AzDceDetails can be build before calling this cmdlet using this syntax
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose -Verbose:$Verbose
 
    .PARAMETER DcrResourceGroup
    This is name of the resource group, where Data Collection Rules will be stored

    .PARAMETER DcrName
    This is name of the Data Collection Rule to use for the upload
    Function will automatically look check in a global variable ($global:AzDcrDetails) - or do a query using Azure Resource Graph to find DCR with name
    Goal is to find the DCR immunetable id on the DCR

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
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

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
                                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    # we see that structure is missing, so we set the flag to enforce creating both DCR and table
    $StructureCheck

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !
    VERBOSE: GET with 0-byte payload
    VERBOSE:   LogAnalytics table wasn't found !
    VERBOSE:   DCR was not found [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ]
    $True

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


    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: Found required DCE info using Azure Resource Graph
    VERBOSE: 
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 898-byte response of content type application/json; charset=utf-8
    VERBOSE: Found required LogAnalytics info
    VERBOSE: 
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 291-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: Creating/updating DCR [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ] with limited payload
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/micros
    oft.insights/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTESTV2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 2033-byte response of content type application/json; charset=utf-8


    StatusCode        : 200
    StatusDescription : OK
    Content           : {"properties":{"immutableId":"dcr-0189d991f81f43efbcfb6fc520541452","dataCollectionEndpointId":"/subscriptions/fce4f2
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
    RawContentLength  : 2033

    VERBOSE: 
    VERBOSE: Updating DCR [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ] with full schema
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/micros
    oft.insights/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTESTV2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4485-byte response of content type application/json; charset=utf-8
    StatusCode        : 200
    StatusDescription : OK
    Content           : {"properties":{"immutableId":"dcr-0189d991f81f43efbcfb6fc520541452","dataCollectionEndpointId":"/subscriptions/fce4f2
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
    RawContentLength  : 4485

    VERBOSE: 
    VERBOSE: Waiting 10 sec to let Azure sync up so DCR rule can be retrieved from Azure Resource Graph
    VERBOSE: 
    VERBOSE: Getting Data Collection Rules from Azure Resource Graph .... Please Wait !
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 203914-byte response of content type application/json; charset=utf-8
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [array]$SchemaSourceObject,
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
            [Parameter(mandatory)]
                [string]$DceName,
            [Parameter(mandatory)]
                [string]$DcrResourceGroup,
            [Parameter(mandatory)]
                [string]$DcrName,
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter(mandatory)]
                [boolean]$AzDcrSetLogIngestApiAppPermissionsDcrLevel,
            [Parameter(mandatory)]
                [string]$LogIngestServicePricipleObjectId,
            [Parameter()]
                [string]$SchemaMode = "Merge",     # Merge = Merge new properties into existing schema, Overwrite = use source object schema
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
                        $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                        $ResponseData       += $ResponseRaw.content
                        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

                        While ($ResponseNextLink -ne $null)
                            {
                                $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
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
        $LogWorkspaceId = (invoke-restmethod -UseBasicParsing -Uri $LogWorkspaceUrl -Method GET -Headers $Headers).properties.customerId
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

        $DcrSubscription                            = ($AzLogWorkspaceResourceId -split "/")[2]
        $DcrLogWorkspaceName                        = ($AzLogWorkspaceResourceId -split "/")[-1]
        $DcrResourceId                              = "/subscriptions/$($DcrSubscription)/resourceGroups/$($DcrResourceGroup)/providers/microsoft.insights/dataCollectionRules/$($DcrName)"


    #--------------------------------------------------------------------------
    # Get existing DCR, if found
    #--------------------------------------------------------------------------

        $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
        Try
            {
                $Dcr = invoke-webrequest -UseBasicParsing -Uri $Uri -Method GET -Headers $Headers
            }
        Catch
            {
            }


    
    #--------------------------------------------------------------------------
    # DCR was NOT found (create) - or we do an Overwrite
    #--------------------------------------------------------------------------
        If ( (!($Dcr)) -or ($SchemaMode -eq "Overwrite") )
            {
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

                    Write-Verbose ""
                    Write-Verbose "Creating/updating DCR [ $($DcrName) ] with limited payload"
                    Write-Verbose $DcrResourceId

                    $DcrPayload = $DcrObject | ConvertTo-Json -Depth 20

                    $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
                    invoke-webrequest -UseBasicParsing -Uri $Uri -Method PUT -Body $DcrPayload -Headers $Headers
        
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

                    Write-Verbose ""
                    Write-Verbose "Updating DCR [ $($DcrName) ] with full payload"
                    Write-Verbose $DcrResourceId

                    $DcrPayload = $DcrObject | ConvertTo-Json -Depth 20

                    $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
                    invoke-webrequest -UseBasicParsing -Uri $Uri -Method PUT -Body $DcrPayload -Headers $Headers


                #--------------------------------------------------------------------------
                # Continue - sleep 10 sec to let Azure Resource Graph pick up the new DCR
                #--------------------------------------------------------------------------

                    Write-Verbose ""
                    Write-Verbose "Waiting 10 sec to let Azure sync up so DCR rule can be retrieved from Azure Resource Graph"
                    Start-Sleep -Seconds 10

                #--------------------------------------------------------------------------
                # updating DCR list using Azure Resource Graph due to new DCR was created
                #--------------------------------------------------------------------------

                    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

                #--------------------------------------------------------------------------
                # delegating Monitor Metrics Publisher Rolepermission to Log Ingest App
                #--------------------------------------------------------------------------

                    If ($AzDcrSetLogIngestApiAppPermissionsDcrLevel -eq $true)
                        {
                            $DcrRule = $global:AzDcrDetails | where-Object { $_.name -eq $DcrName }
                            $DcrRuleId = $DcrRule.id

                            Write-Verbose ""
                            Write-Verbose "Setting Monitor Metrics Publisher Role permissions on DCR [ $($DcrName) ]"

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
                                    invoke-restmethod -UseBasicParsing -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
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
                                    Write-Error "  Error 513 - You are sending too large data - make the dataset smaller"
                                }
                            Else
                                {
                                    Write-Error $result
                                }

                            # Sleep 10 sec to let Azure sync up
                            Write-Verbose ""
                            Write-Verbose "Waiting 10 sec to let Azure sync up for permissions to replicate"
                            Start-Sleep -Seconds 10
                            Write-Verbose ""
                        }
        }

    #--------------------------------------------------------------------------
    # DCR was found - we will do either a MERGE or OVERWRITE
    #--------------------------------------------------------------------------
        ElseIf ( ($Dcr) -and ($SchemaMode -eq "Merge") )
            {

                $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($TableName)_CL?api-version=2021-12-01-preview"
                $TableStatus = Try
                                    {
                                        invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
                                    }
                               Catch
                                    {
                                    }


                If ($TableStatus)
                    {
                        $CurrentTableSchema = $TableStatus.properties.schema.columns
                    }

                # start by building new schema hash, based on existing schema in LogAnalytics custom log table
                    $SchemaArrayDCRFormatHash = @()
                    ForEach ($Property in $CurrentTableSchema)
                        {
                            $Name = $Property.name
                            $Type = $Property.type

                            # Add all properties except TimeGenerated as it only exist in tables - not DCRs
                            If ($Name -ne "TimeGenerated")
                                {
                                    $SchemaArrayDCRFormatHash += @{
                                                                    name        = $name
                                                                    type        = $type
                                                                  }
                                }
                        }

                # enum $SchemaSourceObject - and check if it exists in $SchemaArrayLogAnalyticsTableFormatHash
                $UpdateDCR = $False
                ForEach ($PropertySource in $SchemaSourceObject)
                    {
                        $PropertyFound = $false
                        ForEach ($Property in $SchemaArrayDCRFormatHash)
                            {
                                If ($Property.name -eq $PropertySource.name)
                                    {
                                        $PropertyFound = $true
                                    }

                            }

                        If ($PropertyFound -eq $true)
                            {
                                # Name already found ... skipping
                            }
                        Else
                            {
                                # DCR must be updated, changes was detected !
                                $UpdateDCR = $true
                                
                                Write-verbose "SchemaMode = Merge: Adding property $($PropertySource.name)"
                                $SchemaArrayDCRFormatHash += @{
                                                                name        = $PropertySource.name
                                                                type        = $PropertySource.type
                                                              }
                            }
                    }



                    #--------------------------------------------------------------------------
                    # Merge: build full payload to create DCR for log ingest (api) to custom logs
                    #--------------------------------------------------------------------------
                        If ($UpdateDCR -eq $true)
                            {
                                $DcrObject = [pscustomobject][ordered]@{
                                                properties = @{
                                                                dataCollectionEndpointId = $DceResourceId
                                                                streamDeclarations = @{
                                                                                        $StreamName = @{
	  				                                                                                        columns = @(
                                                                                                                        $SchemaArrayDCRFormatHash
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
                            # Update DCR using merged payload
                            #--------------------------------------------------------------------------

                                Write-Verbose ""
                                Write-Verbose "Merge: Updating DCR [ $($DcrName) ] with new properties in schema"
                                Write-Verbose $DcrResourceId

                                $DcrPayload = $DcrObject | ConvertTo-Json -Depth 20

                                $Uri = "https://management.azure.com" + "$DcrResourceId" + "?api-version=2022-06-01"
                                invoke-webrequest -UseBasicParsing -Uri $Uri -Method PUT -Body $DcrPayload -Headers $Headers
                    }
            }

            
}


Function CreateUpdate-AzLogAnalyticsCustomLogTableDcr
{
  <#
    .SYNOPSIS
    Create or Update Azure LogAnalytics Custom Log table - used together with Data Collection Rules (DCR)
    for Log Ingestion API upload to LogAnalytics

    .DESCRIPTION
    Uses schema based on source object

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER SchemaSourceObject
    This is the schema in hash table format coming from the source object

    .PARAMETER SchemaMode
    SchemaMode = Merge (default)
    It will do a merge/union of new properties and existing schema properties. DCR will import schema from table

    SchemaMode = Overwrite
    It will overwrite existing schema in DCR/table – based on source object schema
    This parameter can be useful for separate overflow work

    .PARAMETER AzLogWorkspaceResourceId
    This is the Loganaytics Resource Id

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

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

    $DceName                                         = "dce-log-platform-management-client-demo1-p" 
    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 
    $AzDcrPrefixClient                               = "clt1" 

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

    $StructureCheck = Get-AzLogAnalyticsTableAzDataCollectionRuleStatus -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -TableName $TableName -DcrName $DcrName -SchemaSourceObject $Schema `
                                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose


    # we see that structure is missing, so we set the flag to enforce creating both DCR and table
    $StructureCheck


    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE:   Checking LogAnalytics table and Data Collection Rule configuration .... Please Wait !
    VERBOSE: GET with 0-byte payload
    VERBOSE:   LogAnalytics table wasn't found !
    VERBOSE:   DCR was not found [ dcr-clt1-InvClientComputerOSInfoTESTV2_CL ]
    $True

    # build schema to be used for LogAnalytics Table
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType Table -Verbose:$Verbose

    CreateUpdate-AzLogAnalyticsCustomLogTableDcr -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -SchemaSourceObject $Schema -TableName $TableName `
                                                    -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose 

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: 
    VERBOSE: Trying to update existing LogAnalytics table schema for table [ InvClientComputerOSInfoTESTV2_CL ] in 
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PATCH with -1-byte payload
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7761-byte response of content type application/json; charset=utf-8
    VERBOSE: 
    VERBOSE: LogAnalytics Table doesn't exist or problems detected .... creating table [ InvClientComputerOSInfoTESTV2_CL ] in
    VERBOSE: /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/works
    paces/log-platform-management-client-demo1-p
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 7761-byte response of content type application/json; charset=utf-8


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
    RawContentLength  : 7761
 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter(mandatory)]
                [array]$SchemaSourceObject,
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
            [Parameter()]
                [string]$SchemaMode = "Merge",     # Merge = Merge new properties into existing schema, Overwrite = use source object schema
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
    # TableCheck
    #--------------------------------------------------------------------------
        $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($TableName)_CL?api-version=2021-12-01-preview"
        $TableStatus = Try
                            {
                                invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
                            }
                        Catch
                            {
                                If ($SchemaMode -eq "Merge")
                                    {
                                        # force SchemaMode to Overwrite (create/update)
                                        $SchemaMode = "Overwrite"
                                    }
                            }

    #--------------------------------------------------------------------------
    # Compare schema between source object schema and Azure LogAnalytics Table
    #--------------------------------------------------------------------------

        If ($TableStatus)
            {
                $CurrentTableSchema = $TableStatus.properties.schema.columns
            }

    #--------------------------------------------------------------------------
    # LogAnalytics Table check
    #--------------------------------------------------------------------------

        $Table         = $TableName  + "_CL"    # TableName with _CL (CustomLog)

        If ($Table.Length -gt 45)
            {
                Write-Error "ERROR - Reduce length of tablename, as it has a maximum of 45 characters (current length: $($Table.Length))"
            }

    #-----------------------------------------------------------------------------------------------
    # SchemaMode = Overwrite - Creating/Updating LogAnalytics Table based upon data source schema
    #-----------------------------------------------------------------------------------------------
    If ($SchemaMode -eq "Overwrite")
        {
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
                    Write-Verbose ""
                    Write-Verbose "Trying to update existing LogAnalytics table schema for table [ $($Table) ] in "
                    Write-Verbose $AzLogWorkspaceResourceId

                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                }
            Catch
                {

                    Write-Verbose ""
                    Write-Verbose "Internal error 500 - recreating table"

                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method DELETE -Headers $Headers
                                
                    Start-Sleep -Seconds 10
                                
                    invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                }
        }

    #-----------------------------------------------------------------------------------------------
    # SchemaMode = Merge - Merging new properties into existing schema
    #-----------------------------------------------------------------------------------------------
    If ($SchemaMode -eq "Merge")
        {
            # start by building new schema hash, based on existing schema in LogAnalytics custom log table
                $SchemaArrayLogAnalyticsTableFormatHash = @()
                ForEach ($Property in $CurrentTableSchema)
                    {
                        $Name = $Property.name
                        $Type = $Property.type

                        $SchemaArrayLogAnalyticsTableFormatHash += @{
                                                                      name        = $name
                                                                      type        = $type
                                                                      description = ""
                                                                   }
                    }


            # enum $SchemaSourceObject - and check if it exists in $SchemaArrayLogAnalyticsTableFormatHash
            $UpdateTable = $False
            ForEach ($PropertySource in $SchemaSourceObject)
                {
                    $PropertyFound = $false
                    ForEach ($Property in $SchemaArrayLogAnalyticsTableFormatHash)
                        {
                            If ($Property.name -eq $PropertySource.name)
                                {
                                    $PropertyFound = $true
                                }

                        }

                    If ($PropertyFound -eq $true)
                        {
                            # Name already found ... skipping
                        }
                    Else
                        {
                            # table must be updated, changes detected in merge-mode
                            $UpdateTable = $true

                            Write-verbose "SchemaMode = Merge: Adding property $($PropertySource.name)"
                            $SchemaArrayLogAnalyticsTableFormatHash += @{
                                                                            name        = $PropertySource.name
                                                                            type        = $PropertySource.type
                                                                            description = ""
                                                                        }
                        }
                }

            If ($UpdateTable -eq $true)
                {            
                    # new table structure with added properties (merging)
                        $tableBodyPut   = @{
                                                properties = @{
                                                                schema = @{
                                                                                name    = $Table
                                                                                columns = @($SchemaArrayLogAnalyticsTableFormatHash)
                                                                            }
                                                            }
                                           } | ConvertTo-Json -Depth 10

                    # create/update table schema using REST
                    $TableUrl = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables/$($Table)?api-version=2021-12-01-preview"

                    Try
                        {
                            Write-Verbose ""
                            Write-Verbose "Trying to update existing LogAnalytics table schema for table [ $($Table) ] in "
                            Write-Verbose $AzLogWorkspaceResourceId

                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                        }
                    Catch
                        {

                            Write-Verbose ""
                            Write-Verbose "Internal error 500 - recreating table"

                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method DELETE -Headers $Headers
                                
                            Start-Sleep -Seconds 10
                                
                            invoke-webrequest -UseBasicParsing -Uri $TableUrl -Method PUT -Headers $Headers -Body $TablebodyPut
                        }
                }
        }
        
    return
}


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


Function Delete-AzLogAnalyticsCustomLogTables
{
 <#
    .SYNOPSIS
    Deletes the Azure Loganalytics defined in like-format, so you can fast clean-up for example after demo or testing

    .DESCRIPTION
    Used to delete many tables in one task

    .PARAMETER TableNameLike
    Here you can put in the table name(s) you wan to delete using like-format - sample *demo* 

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

    $LogAnalyticsWorkspaceResourceId                 = "/subscriptions/xxxxxx/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log-platform-management-client-demo1-p" 


    # delete Azure LogAnalytics custom logs tables with name like - * can be used like *demo*
    Delete-AzLogAnalyticsCustomLogTables -TableNameLike "*test*" -AzLogWorkspaceResourceId $LogAnalyticsWorkspaceResourceId -verbose:$verbose

    # Output
    Getting list of tables in 
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log
    -platform-management-client-demo1-p
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 1562867-byte response of content type application/json; charset=utf-8
    LogAnalytics Resource Id
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log
    -platform-management-client-demo1-p

    Table deletions in scope:
    InvClientComputerOSInfoTESTV2_CL
    InvClientComputerOSInfoTest3V2_CL
    InvClientComputerOSInfoTest4V2_CL
    InvClientComputerOSInfoTest5V2_CL
    Deleting LogAnalytics table [ InvClientComputerOSInfoTESTV2_CL ] ... Please Wait !
    VERBOSE: DELETE with 0-byte payload
    VERBOSE: received 0-byte response of content type 

    Deleting LogAnalytics table [ InvClientComputerOSInfoTest3V2_CL ] ... Please Wait !
    VERBOSE: DELETE with 0-byte payload
    VERBOSE: received 0-byte response of content type 

    Deleting LogAnalytics table [ InvClientComputerOSInfoTest4V2_CL ] ... Please Wait !
    VERBOSE: DELETE with 0-byte payload
    VERBOSE: received 0-byte response of content type 

    Deleting LogAnalytics table [ InvClientComputerOSInfoTest5V2_CL ] ... Please Wait !
    VERBOSE: DELETE with 0-byte payload
    VERBOSE: received 0-byte response of content type 

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$TableNameLike,
            [Parameter(mandatory)]
                [string]$AzLogWorkspaceResourceId,
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
    # Getting list of Azure LogAnalytics tables
    #--------------------------------------------------------------------------

        Write-host "Getting list of tables in "
        Write-host $AzLogWorkspaceResourceId

        # create/update table schema using REST
        $TableUrl   = "https://management.azure.com" + $AzLogWorkspaceResourceId + "/tables?api-version=2021-12-01-preview"
        $TablesRaw  = invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
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
                                                    invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method DELETE -Headers $Headers
                                                }
                                        }
                                    1
                                        {
                                            Write-Host "No" -ForegroundColor Red
                                        }
                                }
            }

}


Function Filter-ObjectExcludeProperty
{
  <#
    .SYNOPSIS
    Removes columns from the object which is considered "noice" and shouldn't be send to logs

    .DESCRIPTION
    Ensures that the log schema and data looks nice and clean

    .PARAMETER Data
    Object to modify

    .PARAMETER ExcludeProperty
    Array of columns to remove from the data object

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Variables
    #-------------------------------------------------------------------------------------------
    $Verbose                   = $true

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

    # we try to see the data in JSON format - and notice some columns, which we want to remote (noice)
    $DataVariable[0] | ConvertTo-Json

    # We remove unnecessary columns in schema (StartInfo, __NounName, Threads) for all records
    $DataVariable = Filter-ObjectExcludeProperty -Data $DataVariable -ExcludeProperty StartInfo, __NounName, Threads -Verbose:$Verbose

    # Now we can see, that data was removed - we have removed data, which aren't relevant
    $DataVariable[0] | ConvertTo-Json

    # Schema after changes - we see the 3 columns (StartInfo, __NounName, Threads) are gone
    Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose
      
    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
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
    Id_                        string  
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
    NounName                   dynamic 
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
    StartTime                  datetime
    SynchronizingObject        dynamic 
    TotalProcessorTime         dynamic 
    Type_                      string  
    UserLoggedOn               string  
    UserProcessorTime          dynamic 
    VirtualMemorySize          int     
    VirtualMemorySize64        int     
    VM                         int     
    WorkingSet                 int     
    WorkingSet64               int     
    WS                         int 
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [array]$ExcludeProperty
         )

    $Data = $Data | Select-Object * -ExcludeProperty $ExcludeProperty
    Return $Data
}


Function Get-AzAccessTokenManagement
{
  <#
    .SYNOPSIS
    Get access token for connecting management.azure.com - used for REST API connectivity

    .DESCRIPTION
    Can be used under current connected user - or by Azure app connectivity with secret

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    JSON-header to use in invoke-webrequest -UseBasicParsing / invoke-restmethod -UseBasicParsing commands

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    # using App
    $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                           -AzAppSecret $AzAppSecret `
                                           -TenantId $TenantId -Verbose:$Verbose

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    $Headers

    Name                           Value                                                                                                     
    ----                           -----                                                                                                     
    Accept                         application/json                                                                                          
    Content-Type                   application/json                                                                                          
    Authorization                  Bearer xxxxxx



    # connect using currently logged on admin
    $Headers = Get-AzAccessTokenManagement

    #Output sample
    $Headers

    Name                           Value                                                                                                     
    ----                           -----                                                                                                     
    Accept                         application/json                                                                                          
    Content-Type                   application/json                                                                                          
    Authorization                  Bearer xxxxxx
 #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )


    If ( ($AzAppId) -and ($AzAppSecret) -and ($TenantId) )
        {
            $AccessTokenUri = 'https://management.azure.com/'
            $oAuthUri       = "https://login.microsoftonline.com/$($TenantId)/oauth2/token"
            $authBody       = [Ordered] @{
                                            resource = $AccessTokenUri
                                            client_id = $AzAppId
                                            client_secret = $AzAppSecret
                                            grant_type = 'client_credentials'
                                         }
            $authResponse = invoke-restmethod -UseBasicParsing -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
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
            $AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/ -Verbose:$Verbose
            $Token = $AccessToken.Token

            $Headers = @{
                            'Content-Type' = 'application/json'
                            'Accept' = 'application/json'
                            'Authorization' = "Bearer $token"
                        }
        }

    Return [array]$Headers
}


Function Get-AzDataCollectionRuleTransformKql
{
 <#
    .SYNOPSIS
    Gets the current tranformKql parameter on an existing DCR with the provided parameter

    .DESCRIPTION
    Used to see the current transformation on a data collection rule

    .PARAMETER $DcrResourceId
    This is the resource id of the data collection rule

    .PARAMETER AzAppId
    This is the Azure app id og an app with Contributor permissions in LogAnalytics + Resource Group for DCRs
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Output of REST GET command. Should be 200 for success

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
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
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method GET -Headers $Headers

    #--------------------------------------------------------------------------
    # show object
    #--------------------------------------------------------------------------

        ForEach ($DataFlow in $DCR.properties.dataFlows)
            {
                Write-Output $DataFlow.transformKql
            }
}


Function Get-AzDceListAll
{
  <#
    .SYNOPSIS
    Builds list of all Data Collection Endpoints (DCEs), which can be retrieved by Azure using the RBAC context of the Log Ingestion App

    .DESCRIPTION
    Data is retrieved using Azure Resource Graph
    Result is saved in global-variable in Powershell
    Main reason for saving as global-variable is to optimize number of times to do lookup - due to throttling in Azure Resource Graph

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Build data array
    #-------------------------------------------------------------------------------------------

    # building global variable with all DCEs, which can be viewed by Log Ingestion app
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
    $global:AzDceDetails

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    id               : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-demo1-p/provi
                       ders/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-demo1-p
    name             : dce-log-platform-management-client-demo1-p
    type             : microsoft.insights/datacollectionendpoints
    tenantId         : f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e
    kind             : 
    location         : westeurope
    resourceGroup    : rg-dce-log-platform-management-client-demo1-p
    subscriptionId   : fce4f282-fcc6-43fb-94d8-bf1701b862c3
    managedBy        : 
    sku              : 
    plan             : 
    properties       : @{provisioningState=Succeeded; description=DCE for LogIngest to LogAnalytics log-platform-management-client-demo1-p; n
                       etworkAcls=; immutableId=dce-7a8a2d176844444b9e89719b702dccec; configurationAccess=; logsIngestion=; metricsIngestion=
                       }
    tags             : 
    identity         : 
    zones            : 
    extendedLocation :
  #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

    Write-Verbose ""
    Write-Verbose "Getting Data Collection Endpoints from Azure Resource Graph .... Please Wait !"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

    #--------------------------------------------------------------------------
    # Get DCEs from Azure Resource Graph
    #--------------------------------------------------------------------------

        $AzGraphQuery = @{
                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionendpoints" '
                            } | ConvertTo-Json -Depth 20

        $ResponseData = @()

        $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
        $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
        $ResponseData       += $ResponseRaw.content
        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

        While ($ResponseNextLink -ne $null)
            {
                $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                $ResponseData       += $ResponseRaw.content
                $ResponseNextLink    = $ResponseRaw."@odata.nextLink"
            }
        $DataJson = $ResponseData | ConvertFrom-Json
        $Data     = $DataJson.data

        Return $Data
}


Function Get-AzDcrDceDetails
{
 <#
    .SYNOPSIS
    Retrieves information about data collection rules and data collection endpoints - using Azure Resource Graph

    .DESCRIPTION
    Used to retrieve information about data collection rules and data collection endpoints - using Azure Resource Graph
    Used by other functions which are looking for DCR/DCE by name

    .PARAMETER DcrName
    Here you can put in the DCR name you want to find

    .PARAMETER DceName
    Here you can put in the DCE name you want to find

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Information about DCR/DCE

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    $verbose                                         = $true

    $TenantId                                        = "xxxxx" 
    $LogIngestAppId                                  = "xxxxx" 
    $LogIngestAppSecret                              = "xxxxx" 

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



    $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName -DceName $DceName `
                                            -AzAppId $LogIngestAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

    # required information is returned in the stream as variables $AzDcrDceDetails[0], $AzDcrDceDetails[1], etc
    $AzDcrDceDetails

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-management-client-demo1-p/providers/Microsoft.Insig
    hts/dataCollectionEndpoints/dce-log-platform-management-client-demo1-p
    westeurope
    https://dce-log-platform-management-client-demo1-p-c5hl.westeurope-1.ingest.monitor.azure.com
    dce-7a8a2d176844444b9e89719b702dccec
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTESTV2_CL
    westeurope
    dcr-0189d991f81f43efbcfb6fc520541452
    Custom-InvClientComputerOSInfoTESTV2_CL
    log-platform-management-client-demo1-p
    e74ca75a-c0e6-4933-a4f7-e5ae943fe4ac
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/Microsoft.OperationalInsights/workspaces/log
    -platform-management-client-demo1-p
    source | extend TimeGenerated = now()

 #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$DceName,
            [Parameter()]
                [string]$DcrName,
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
                                    Write-Output "DCE name was not found in index ... fallback to Azure Resource Graph query !"
                                    
                                    $AzGraphQuery = @{
                                                        'query' = 'Resources | where type =~ "microsoft.insights/datacollectionendpoints" '
                                                        } | ConvertTo-Json -Depth 20

                                    $ResponseData = @()

                                    $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
                                    $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                                    $ResponseData       += $ResponseRaw.content
                                    $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

                                    While ($ResponseNextLink -ne $null)
                                        {
                                            $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
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
                Else
                    {
                        $AzGraphQuery = @{
                                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionendpoints" '
                                         } | ConvertTo-Json -Depth 20

                        $ResponseData = @()

                        $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
                        $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                        $ResponseData       += $ResponseRaw.content
                        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

                        While ($ResponseNextLink -ne $null)
                            {
                                $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
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
                                    Write-Output "DCR name was not found in index ... fallback to Azure Resource Graph query !"
                                    
                                    $AzGraphQuery = @{
                                                        'query' = 'Resources | where type =~ "microsoft.insights/datacollectionendpoints" '
                                                        } | ConvertTo-Json -Depth 20

                                    $ResponseData = @()

                                    $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
                                    $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                                    $ResponseData       += $ResponseRaw.content
                                    $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

                                    While ($ResponseNextLink -ne $null)
                                        {
                                            $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
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
                Else
                    {
                        $AzGraphQuery = @{
                                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionrules" '
                                         } | ConvertTo-Json -Depth 20

                        $ResponseData = @()

                        $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
                        $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                        $ResponseData       += $ResponseRaw.content
                        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

                        While ($ResponseNextLink -ne $null)
                            {
                                $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
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


Function Get-AzDcrListAll
{
  <#
    .SYNOPSIS
    Builds list of all Data Collection Rules (DCRs), which can be retrieved by Azure using the RBAC context of the Log Ingestion App

    .DESCRIPTION
    Data is retrieved using Azure Resource Graph
    Result is saved in global-variable in Powershell
    Main reason for saving as global-variable is to optimize number of times to do lookup - due to throttling in Azure Resource Graph

    .PARAMETER AzAppId
    This is the Azure app id
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

    .EXAMPLE
    #-------------------------------------------------------------------------------------------
    # Build data array
    #-------------------------------------------------------------------------------------------

    # building global variable with all DCRs, which can be viewed by Log Ingestion app
    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId
    $global:AzDcrDetails

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    id               : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/provi
                       ders/microsoft.insights/dataCollectionRules/dcr-clt1-InvClientWindowsUpdateLastInstallationsV2_CL
    name             : dcr-clt1-InvClientWindowsUpdateLastInstallationsV2_CL
    type             : microsoft.insights/datacollectionrules
    tenantId         : f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e
    kind             : 
    location         : westeurope
    resourceGroup    : rg-dcr-log-platform-management-client-demo1-p
    subscriptionId   : fce4f282-fcc6-43fb-94d8-bf1701b862c3
    managedBy        : 
    sku              : 
    plan             : 
    properties       : @{provisioningState=Succeeded; destinations=; immutableId=dcr-536e17acf300416a87ec3e48408c5c51; dataFlows=System.Objec
                       t[]; dataCollectionEndpointId=/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-m
                       anagement-client-demo1-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-demo1
                       -p; streamDeclarations=}
    tags             : 
    identity         : 
    zones            : 
    extendedLocation : 

    id               : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/provi
                       ders/microsoft.insights/dataCollectionRules/dcr-clt1-InvClientWindowsUpdateLastResultsV2_CL
    name             : dcr-clt1-InvClientWindowsUpdateLastResultsV2_CL
    type             : microsoft.insights/datacollectionrules
    tenantId         : f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e
    kind             : 
    location         : westeurope
    resourceGroup    : rg-dcr-log-platform-management-client-demo1-p
    subscriptionId   : fce4f282-fcc6-43fb-94d8-bf1701b862c3
    managedBy        : 
    sku              : 
    plan             : 
    properties       : @{provisioningState=Succeeded; destinations=; immutableId=dcr-70fc262b839c41b4a3b1bd83b9f6d323; dataFlows=System.Objec
                       t[]; dataCollectionEndpointId=/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-m
                       anagement-client-demo1-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-demo1
                       -p; streamDeclarations=}
    tags             : 
    identity         : 
    zones            : 
    extendedLocation : 

    id               : /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/provi
                       ders/microsoft.insights/dataCollectionRules/dcr-clt1-InvClientWindowsUpdatePendingUpdatesV2_CL
    name             : dcr-clt1-InvClientWindowsUpdatePendingUpdatesV2_CL
    type             : microsoft.insights/datacollectionrules
    tenantId         : f0fa27a0-8e7c-4f63-9a77-ec94786b7c9e
    kind             : 
    location         : westeurope
    resourceGroup    : rg-dcr-log-platform-management-client-demo1-p
    subscriptionId   : fce4f282-fcc6-43fb-94d8-bf1701b862c3
    managedBy        : 
    sku              : 
    plan             : 
    properties       : @{provisioningState=Succeeded; destinations=; immutableId=dcr-a08cb890c5f14bb9af47fe76af051f82; dataFlows=System.Objec
                       t[]; dataCollectionEndpointId=/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dce-log-platform-m
                       anagement-client-demo1-p/providers/Microsoft.Insights/dataCollectionEndpoints/dce-log-platform-management-client-demo1
                       -p; streamDeclarations=}
    tags             : 
    identity         : 
    zones            : 
    extendedLocation : 
  #>

    [CmdletBinding()]
    param(
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

    Write-Verbose ""
    Write-Verbose "Getting Data Collection Rules from Azure Resource Graph .... Please Wait !"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

    #--------------------------------------------------------------------------
    # Get DCRs from Azure Resource Graph
    #--------------------------------------------------------------------------

        $AzGraphQuery = @{
                            'query' = 'Resources | where type =~ "microsoft.insights/datacollectionrules" '
                            } | ConvertTo-Json -Depth 20

        $ResponseData = @()

        $AzGraphUri          = "https://management.azure.com/providers/Microsoft.ResourceGraph/resources?api-version=2021-03-01"
        $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
        $ResponseData       += $ResponseRaw.content
        $ResponseNextLink    = $ResponseRaw."@odata.nextLink"

        While ($ResponseNextLink -ne $null)
            {
                $ResponseRaw         = invoke-webrequest -UseBasicParsing -Method POST -Uri $AzGraphUri -Headers $Headers -Body $AzGraphQuery
                $ResponseData       += $ResponseRaw.content
                $ResponseNextLink    = $ResponseRaw."@odata.nextLink"
            }
        $DataJson = $ResponseData | ConvertFrom-Json
        $Data     = $DataJson.data

        Return $Data
}


Function Get-AzLogAnalyticsTableAzDataCollectionRuleStatus
{
 <#
    .SYNOPSIS
    Get status about Azure Loganalytics tables and Data Collection Rule.

    .DESCRIPTION
    Used to detect if table/DCR must be create/updated - or it is valid to send in data

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
	
    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

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
                                    invoke-restmethod -UseBasicParsing -Uri $TableUrl -Method GET -Headers $Headers
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


Function Get-ObjectSchemaAsArray
{
  <#
    .SYNOPSIS
    Gets the schema of the object as array with column-names and their type (strin, boolean, dynamic, etc.)

    .DESCRIPTION
    Used to validate the data structure - and give insight of any potential data manipulation

    .PARAMETER Data
    Object to modify

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

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

    $Schema = Get-ObjectSchemaAsArray -Data $DataVariable
    $Schema

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    name                                      type    
    ----                                      ----    
    BootDevice                                string  
    BuildNumber                               string  
    BuildType                                 string  
    Caption                                   string  
    CodeSet                                   string  
    CollectionTime                            datetime
    Computer                                  string  
    CountryCode                               string  
    CreationClassName                         string  
    CSCreationClassName                       string  
    CSDVersion                                dynamic 
    CSName                                    string  
    CurrentTimeZone                           int     
    DataExecutionPrevention_32BitApplications boolean 
    DataExecutionPrevention_Available         boolean 
    DataExecutionPrevention_Drivers           boolean 
    DataExecutionPrevention_SupportPolicy     int     
    Debug                                     boolean 
    Description                               string  
    Distributed                               boolean 
    EncryptionLevel                           int     
    ForegroundApplicationBoost                int     
    FreePhysicalMemory                        int     
    FreeSpaceInPagingFiles                    int     
    FreeVirtualMemory                         int     
    InstallDate                               datetime
    LargeSystemCache                          dynamic 
    LastBootUpTime                            datetime
    LocalDateTime                             datetime
    Locale                                    string  
    Manufacturer                              string  
    MaxNumberOfProcesses                      long    
    MaxProcessMemorySize                      long    
    MUILanguages                              dynamic 
    Name                                      string  
    NumberOfLicensedUsers                     int     
    NumberOfProcesses                         int     
    NumberOfUsers                             int     
    OperatingSystemSKU                        int     
    Organization                              dynamic 
    OSArchitecture                            string  
    OSLanguage                                int     
    OSProductSuite                            int     
    OSType                                    int     
    OtherTypeDescription                      dynamic 
    PAEEnabled                                dynamic 
    PlusProductID                             dynamic 
    PlusVersionNumber                         dynamic 
    PortableOperatingSystem                   boolean 
    Primary                                   boolean 
    ProductType                               int     
    PSComputerName                            dynamic 
    RegisteredUser                            string  
    SerialNumber                              string  
    ServicePackMajorVersion                   int     
    ServicePackMinorVersion                   int     
    SizeStoredInPagingFiles                   int     
    Status                                    string  
    SuiteMask                                 int     
    SystemDevice                              string  
    SystemDirectory                           string  
    SystemDrive                               string  
    TotalSwapSpaceSize                        dynamic 
    TotalVirtualMemorySize                    int     
    TotalVisibleMemorySize                    int     
    UserLoggedOn                              string  
    Version                                   string  
    WindowsDirectory                          string  

  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter()]
                [ValidateSet("Table", "DCR")]
                [string[]]$ReturnType
         )


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

            If ($ReturnType -eq "Table")
            {
                # Return schema format for LogAnalytics table
                Return $SchemaArrayLogAnalyticsTableFormat
            }
        ElseIf ($ReturnType -eq "DCR")
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat
            }
        Else
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat
            }
}


Function Get-ObjectSchemaAsHash
{
  <#
    .SYNOPSIS
    Gets the schema of the object as hash table with column-names and their type (strin, boolean, dynamic, etc.)

    .DESCRIPTION
    Used to validate the data structure - and give insight of any potential data manipulation
    Support to return in both LogAnalytics table-format and DCR-format

    .PARAMETER Data
    Object to modify

    .PARAMETER ReturnType
    Object to modify

    .INPUTS
    None. You cannot pipe objects

    .OUTPUTS
    Updated object with CollectionTime

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

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

    # build schema to be used for LogAnalytics Table
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType Table -Verbose:$Verbose
    $Schema

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    PS $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType Table -Verbose:$Verbose
        $Schema

    Name                           Value                                                                                                     
    ----                           -----                                                                                                     
    description                                                                                                                              
    name                           TimeGenerated                                                                                             
    type                           datetime                                                                                                  
    description                                                                                                                              
    name                           BootDevice                                                                                                
    type                           string                                                                                                    
    description                                                                                                                              
    name                           BuildNumber                                                                                               
    type                           string                                                                                                    
    description                                                                                                                              
    name                           BuildType                                                                                                 
    type                           string                                                                                                    
    description                                                                                                                              
    name                           Caption                                                                                                   
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CodeSet                                                                                                   
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CollectionTime                                                                                            
    type                           datetime                                                                                                  
    description                                                                                                                              
    name                           Computer                                                                                                  
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CountryCode                                                                                               
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CreationClassName                                                                                         
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CSCreationClassName                                                                                       
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CSDVersion                                                                                                
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           CSName                                                                                                    
    type                           string                                                                                                    
    description                                                                                                                              
    name                           CurrentTimeZone                                                                                           
    type                           int                                                                                                       
    description                                                                                                                              
    name                           DataExecutionPrevention_32BitApplications                                                                 
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           DataExecutionPrevention_Available                                                                         
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           DataExecutionPrevention_Drivers                                                                           
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           DataExecutionPrevention_SupportPolicy                                                                     
    type                           int                                                                                                       
    description                                                                                                                              
    name                           Debug                                                                                                     
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           Description                                                                                               
    type                           string                                                                                                    
    description                                                                                                                              
    name                           Distributed                                                                                               
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           EncryptionLevel                                                                                           
    type                           int                                                                                                       
    description                                                                                                                              
    name                           ForegroundApplicationBoost                                                                                
    type                           int                                                                                                       
    description                                                                                                                              
    name                           FreePhysicalMemory                                                                                        
    type                           int                                                                                                       
    description                                                                                                                              
    name                           FreeSpaceInPagingFiles                                                                                    
    type                           int                                                                                                       
    description                                                                                                                              
    name                           FreeVirtualMemory                                                                                         
    type                           int                                                                                                       
    description                                                                                                                              
    name                           InstallDate                                                                                               
    type                           datetime                                                                                                  
    description                                                                                                                              
    name                           LargeSystemCache                                                                                          
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           LastBootUpTime                                                                                            
    type                           datetime                                                                                                  
    description                                                                                                                              
    name                           LocalDateTime                                                                                             
    type                           datetime                                                                                                  
    description                                                                                                                              
    name                           Locale                                                                                                    
    type                           string                                                                                                    
    description                                                                                                                              
    name                           Manufacturer                                                                                              
    type                           string                                                                                                    
    description                                                                                                                              
    name                           MaxNumberOfProcesses                                                                                      
    type                           long                                                                                                      
    description                                                                                                                              
    name                           MaxProcessMemorySize                                                                                      
    type                           long                                                                                                      
    description                                                                                                                              
    name                           MUILanguages                                                                                              
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           Name                                                                                                      
    type                           string                                                                                                    
    description                                                                                                                              
    name                           NumberOfLicensedUsers                                                                                     
    type                           int                                                                                                       
    description                                                                                                                              
    name                           NumberOfProcesses                                                                                         
    type                           int                                                                                                       
    description                                                                                                                              
    name                           NumberOfUsers                                                                                             
    type                           int                                                                                                       
    description                                                                                                                              
    name                           OperatingSystemSKU                                                                                        
    type                           int                                                                                                       
    description                                                                                                                              
    name                           Organization                                                                                              
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           OSArchitecture                                                                                            
    type                           string                                                                                                    
    description                                                                                                                              
    name                           OSLanguage                                                                                                
    type                           int                                                                                                       
    description                                                                                                                              
    name                           OSProductSuite                                                                                            
    type                           int                                                                                                       
    description                                                                                                                              
    name                           OSType                                                                                                    
    type                           int                                                                                                       
    description                                                                                                                              
    name                           OtherTypeDescription                                                                                      
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           PAEEnabled                                                                                                
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           PlusProductID                                                                                             
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           PlusVersionNumber                                                                                         
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           PortableOperatingSystem                                                                                   
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           Primary                                                                                                   
    type                           boolean                                                                                                   
    description                                                                                                                              
    name                           ProductType                                                                                               
    type                           int                                                                                                       
    description                                                                                                                              
    name                           PSComputerName                                                                                            
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           RegisteredUser                                                                                            
    type                           string                                                                                                    
    description                                                                                                                              
    name                           SerialNumber                                                                                              
    type                           string                                                                                                    
    description                                                                                                                              
    name                           ServicePackMajorVersion                                                                                   
    type                           int                                                                                                       
    description                                                                                                                              
    name                           ServicePackMinorVersion                                                                                   
    type                           int                                                                                                       
    description                                                                                                                              
    name                           SizeStoredInPagingFiles                                                                                   
    type                           int                                                                                                       
    description                                                                                                                              
    name                           Status                                                                                                    
    type                           string                                                                                                    
    description                                                                                                                              
    name                           SuiteMask                                                                                                 
    type                           int                                                                                                       
    description                                                                                                                              
    name                           SystemDevice                                                                                              
    type                           string                                                                                                    
    description                                                                                                                              
    name                           SystemDirectory                                                                                           
    type                           string                                                                                                    
    description                                                                                                                              
    name                           SystemDrive                                                                                               
    type                           string                                                                                                    
    description                                                                                                                              
    name                           TotalSwapSpaceSize                                                                                        
    type                           dynamic                                                                                                   
    description                                                                                                                              
    name                           TotalVirtualMemorySize                                                                                    
    type                           int                                                                                                       
    description                                                                                                                              
    name                           TotalVisibleMemorySize                                                                                    
    type                           int                                                                                                       
    description                                                                                                                              
    name                           UserLoggedOn                                                                                              
    type                           string                                                                                                    
    description                                                                                                                              
    name                           Version                                                                                                   
    type                           string                                                                                                    
    description                                                                                                                              
    name                           WindowsDirectory                                                                                          
    type                           string   

    # build schema to be used for DCR
    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType DCR -Verbose:$verbose
    $Schema

    $Schema = Get-ObjectSchemaAsHash -Data $DataVariable -ReturnType DCR -Verbose:$verbose
    $Schema
    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------

    Name                           Value                                                                                                     
    ----                           -----                                                                                                     
    name                           BootDevice                                                                                                
    type                           string                                                                                                    
    name                           BuildNumber                                                                                               
    type                           string                                                                                                    
    name                           BuildType                                                                                                 
    type                           string                                                                                                    
    name                           Caption                                                                                                   
    type                           string                                                                                                    
    name                           CodeSet                                                                                                   
    type                           string                                                                                                    
    name                           CollectionTime                                                                                            
    type                           datetime                                                                                                  
    name                           Computer                                                                                                  
    type                           string                                                                                                    
    name                           CountryCode                                                                                               
    type                           string                                                                                                    
    name                           CreationClassName                                                                                         
    type                           string                                                                                                    
    name                           CSCreationClassName                                                                                       
    type                           string                                                                                                    
    name                           CSDVersion                                                                                                
    type                           dynamic                                                                                                   
    name                           CSName                                                                                                    
    type                           string                                                                                                    
    name                           CurrentTimeZone                                                                                           
    type                           int                                                                                                       
    name                           DataExecutionPrevention_32BitApplications                                                                 
    type                           boolean                                                                                                   
    name                           DataExecutionPrevention_Available                                                                         
    type                           boolean                                                                                                   
    name                           DataExecutionPrevention_Drivers                                                                           
    type                           boolean                                                                                                   
    name                           DataExecutionPrevention_SupportPolicy                                                                     
    type                           int                                                                                                       
    name                           Debug                                                                                                     
    type                           boolean                                                                                                   
    name                           Description                                                                                               
    type                           string                                                                                                    
    name                           Distributed                                                                                               
    type                           boolean                                                                                                   
    name                           EncryptionLevel                                                                                           
    type                           int                                                                                                       
    name                           ForegroundApplicationBoost                                                                                
    type                           int                                                                                                       
    name                           FreePhysicalMemory                                                                                        
    type                           int                                                                                                       
    name                           FreeSpaceInPagingFiles                                                                                    
    type                           int                                                                                                       
    name                           FreeVirtualMemory                                                                                         
    type                           int                                                                                                       
    name                           InstallDate                                                                                               
    type                           datetime                                                                                                  
    name                           LargeSystemCache                                                                                          
    type                           dynamic                                                                                                   
    name                           LastBootUpTime                                                                                            
    type                           datetime                                                                                                  
    name                           LocalDateTime                                                                                             
    type                           datetime                                                                                                  
    name                           Locale                                                                                                    
    type                           string                                                                                                    
    name                           Manufacturer                                                                                              
    type                           string                                                                                                    
    name                           MaxNumberOfProcesses                                                                                      
    type                           long                                                                                                      
    name                           MaxProcessMemorySize                                                                                      
    type                           long                                                                                                      
    name                           MUILanguages                                                                                              
    type                           dynamic                                                                                                   
    name                           Name                                                                                                      
    type                           string                                                                                                    
    name                           NumberOfLicensedUsers                                                                                     
    type                           int                                                                                                       
    name                           NumberOfProcesses                                                                                         
    type                           int                                                                                                       
    name                           NumberOfUsers                                                                                             
    type                           int                                                                                                       
    name                           OperatingSystemSKU                                                                                        
    type                           int                                                                                                       
    name                           Organization                                                                                              
    type                           dynamic                                                                                                   
    name                           OSArchitecture                                                                                            
    type                           string                                                                                                    
    name                           OSLanguage                                                                                                
    type                           int                                                                                                       
    name                           OSProductSuite                                                                                            
    type                           int                                                                                                       
    name                           OSType                                                                                                    
    type                           int                                                                                                       
    name                           OtherTypeDescription                                                                                      
    type                           dynamic                                                                                                   
    name                           PAEEnabled                                                                                                
    type                           dynamic                                                                                                   
    name                           PlusProductID                                                                                             
    type                           dynamic                                                                                                   
    name                           PlusVersionNumber                                                                                         
    type                           dynamic                                                                                                   
    name                           PortableOperatingSystem                                                                                   
    type                           boolean                                                                                                   
    name                           Primary                                                                                                   
    type                           boolean                                                                                                   
    name                           ProductType                                                                                               
    type                           int                                                                                                       
    name                           PSComputerName                                                                                            
    type                           dynamic                                                                                                   
    name                           RegisteredUser                                                                                            
    type                           string                                                                                                    
    name                           SerialNumber                                                                                              
    type                           string                                                                                                    
    name                           ServicePackMajorVersion                                                                                   
    type                           int                                                                                                       
    name                           ServicePackMinorVersion                                                                                   
    type                           int                                                                                                       
    name                           SizeStoredInPagingFiles                                                                                   
    type                           int                                                                                                       
    name                           Status                                                                                                    
    type                           string                                                                                                    
    name                           SuiteMask                                                                                                 
    type                           int                                                                                                       
    name                           SystemDevice                                                                                              
    type                           string                                                                                                    
    name                           SystemDirectory                                                                                           
    type                           string                                                                                                    
    name                           SystemDrive                                                                                               
    type                           string                                                                                                    
    name                           TotalSwapSpaceSize                                                                                        
    type                           dynamic                                                                                                   
    name                           TotalVirtualMemorySize                                                                                    
    type                           int                                                                                                       
    name                           TotalVisibleMemorySize                                                                                    
    type                           int                                                                                                       
    name                           UserLoggedOn                                                                                              
    type                           string                                                                                                    
    name                           Version                                                                                                   
    type                           string                                                                                                    
    name                           WindowsDirectory                                                                                          
    type                           string  
  #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [ValidateSet("Table", "DCR")]
                [string[]]$ReturnType
         )


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

            If ($ReturnType -eq "Table")
            {
                # Return schema format for Table
                $SchemaArrayLogAnalyticsTableFormatHash
            }
        ElseIf ($ReturnType -eq "DCR")
            {
                # Return schema format for DCR
                $SchemaArrayDcrFormatHash
            }
        
        Return
}


Function Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output
{
 <#
    .SYNOPSIS
    Send data to LogAnalytics using Log Ingestion API and Data Collection Rule (combined)

    .DESCRIPTION
    Combined function which will combine 3 functions in one call:
    Get-AzDcrDceDetails
    Post-AzLogAnalyticsLogIngestCustomLogDcrDce

    Data is either sent as one record (if only one exist), batches (calculated value of number of records to send per batch)
    - or BatchAmount (used only if the size of the records changes so you run into problems with limitations. 
    In case of diffent sizes, use 1 for BatchAmount
    Sending data in UTF8 format

    .PARAMETER DceUri
    Here you can put in the DCE uri - typically found using Get-DceDcrDetails

    .PARAMETER DcrImmutableId
    Here you can put in the DCR ImmunetableId - typically found using Get-DceDcrDetails

    .PARAMETER DcrStream
    Here you can put in the DCR Stream name - typically found using Get-DceDcrDetails

    .PARAMETER Tablename
    Specifies the table name in LogAnalytics

    .PARAMETER Data
    This is the data array

    .PARAMETER BatchAmount
    Sometimes it happens, that the data entries are of very different sizes. This parameter will allow you to force to specific amount per batch

    .PARAMETER AzAppId
    This is the Azure app id og an app with Contributor permissions in LogAnalytics + Resource Group for DCRs
        
    .PARAMETER AzAppSecret
    This is the secret of the Azure app

    .PARAMETER TenantId
    This is the Azure AD tenant id

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

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

        
    #-----------------------------------------------------------------------------------------------
    # Upload data to LogAnalytics using DCR / DCE / Log Ingestion API
    #-----------------------------------------------------------------------------------------------

    Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output -DceName $DceName -DcrName $DcrName -Data $DataVariable -TableName $TableName `
                                                        -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1468-byte response of content type application/json; charset=utf-8
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1342-byte response of content type application/json; charset=utf-8
    VERBOSE: POST with -1-byte payload
    VERBOSE: received 1317-byte response of content type application/json; charset=utf-8

      [ 1 / 1 ] - Posting data to Loganalytics table [ InvClientComputerOSInfoTest4V2_CL ] .... Please Wait !
    VERBOSE: POST with -1-byte payload
    VERBOSE: received -1-byte response of content type 
      SUCCESS - data uploaded to LogAnalytics

    VERBOSE: 

    BootDevice                                : \Device\HarddiskVolume1
    BuildNumber                               : 22621
    BuildType                                 : Multiprocessor Free
    Caption                                   : Microsoft Windows 11 Enterprise
    CodeSet                                   : 1252
    CollectionTime                            : 12-03-2023 19:11:15
    Computer                                  : STRV-MOK-DT-02
    CountryCode                               : 1
    CreationClassName                         : Win32_OperatingSystem
    CSCreationClassName                       : Win32_ComputerSystem
    CSDVersion                                : 
    CSName                                    : STRV-MOK-DT-02
    CurrentTimeZone                           : 60
    DataExecutionPrevention_32BitApplications : True
    DataExecutionPrevention_Available         : True
    DataExecutionPrevention_Drivers           : True
    DataExecutionPrevention_SupportPolicy     : 2
    Debug                                     : False
    Description                               : 
    Distributed                               : False
    EncryptionLevel                           : 256
    ForegroundApplicationBoost                : 2
    FreePhysicalMemory                        : 7385644
    FreeSpaceInPagingFiles                    : 14208308
    FreeVirtualMemory                         : 13526060
    InstallDate                               : 21-09-2022 05:56:02
    LargeSystemCache                          : 
    LastBootUpTime                            : 08-03-2023 22:19:03
    LocalDateTime                             : 12-03-2023 18:11:15
    Locale                                    : 0409
    Manufacturer                              : Microsoft Corporation
    MaxNumberOfProcesses                      : 4294967295
    MaxProcessMemorySize                      : 137438953344
    MUILanguages                              : {en-US, en-GB}
    Name                                      : Microsoft Windows 11 Enterprise|C:\WINDOWS|\Device\Harddisk0\Partition3
    NumberOfLicensedUsers                     : 0
    NumberOfProcesses                         : 336
    NumberOfUsers                             : 2
    OperatingSystemSKU                        : 4
    Organization                              : 
    OSArchitecture                            : 64-bit
    OSLanguage                                : 1033
    OSProductSuite                            : 256
    OSType                                    : 18
    OtherTypeDescription                      : 
    PAEEnabled                                : 
    PlusProductID                             : 
    PlusVersionNumber                         : 
    PortableOperatingSystem                   : False
    Primary                                   : True
    ProductType                               : 1
    PSComputerName                            : 
    RegisteredUser                            : mok
    SerialNumber                              : 00330-80000-00000-AA032
    ServicePackMajorVersion                   : 0
    ServicePackMinorVersion                   : 0
    SizeStoredInPagingFiles                   : 15728640
    Status                                    : OK
    SuiteMask                                 : 272
    SystemDevice                              : \Device\HarddiskVolume3
    SystemDirectory                           : C:\WINDOWS\system32
    SystemDrive                               : C:
    TotalSwapSpaceSize                        : 
    TotalVirtualMemorySize                    : 32210960
    TotalVisibleMemorySize                    : 16482320
    UserLoggedOn                              : 
    Version                                   : 10.0.22621
    WindowsDirectory                          : C:\WINDOWS

 #>
    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [Array]$Data,
            [Parameter(mandatory)]
                [AllowEmptyString()]
                [string]$DcrName,
            [Parameter(mandatory)]
                [AllowEmptyString()]
                [string]$DceName,
            [Parameter(mandatory)]
                [string]$TableName,
            [Parameter()]
                [string]$BatchAmount,
            [Parameter()]
                [boolean]$EnableUploadViaLogHub = $false,
            [Parameter()]
                [string]$LogHubPath,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

        # Endpoint sends data directly to Azure, either using public endpoint - or via private link
        If ( ($EnableUploadViaLogHub -eq $false) -or ($EnableUploadViaLogHub -eq $null) )
            {

                $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName -DceName $DceName `
                                                       -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

                Post-AzLogAnalyticsLogIngestCustomLogDcrDce -DceUri $AzDcrDceDetails[2] -DcrImmutableId $AzDcrDceDetails[6] -TableName $TableName `
                                                            -DcrStream $AzDcrDceDetails[7] -Data $Data -BatchAmount $BatchAmount `
                                                            -AzAppId $AzAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose
            }

        # log-hub support - endpoint sends log-data via log-hub (remote internal path). Then Log-hub forwards data to Azure
        ElseIf ( ( $EnableUploadViaLogHub -eq $true ) -and ($LogHubPath) )
            {
                If ($Data)
                    {
                        # Mandatory
                        $LogHubData = New-Object PsCustomObject
                        $LogHubData | Add-Member -MemberType NoteProperty -Name Source -Value $Env:ComputerName
                        $LogHubData | Add-Member -MemberType NoteProperty -Name UploadTime -Value (get-date -Format yyyy-MM-dd_HH-mm-ss)
                        $LogHubData | Add-Member -MemberType NoteProperty -Name TableName -Value $TableName
                        $LogHubData | Add-Member -MemberType NoteProperty -Name DceName -Value $DceName
                        $LogHubData | Add-Member -MemberType NoteProperty -Name DcrName $DcrName
                        $LogHubData | Add-Member -MemberType NoteProperty -Name Data -Value @($Data)

                        # optional
                        If ($BatchAmount)
                            {
                                $LogHubData | Add-Member -MemberType NoteProperty -Name BatchAmount -Value $BatchAmount
                            }
                
                        # Export to JSON format
                        $LogHubFileName = $LogHubPath + "\" + $ENV:ComputerName + "__" + $TableName + "__" + (get-date -Format yyyy-MM-dd_HH-mm-ss) + ".json"
                        Write-host "Writing log-data to file $($LogHubFileName) (log-hub)"

                        $LogHubDataJson = $LogHubData | ConvertTo-Json -Depth 25
                        $LogHubDataJson | Out-File -FilePath $LogHubFileName -Encoding utf8 -Force
                    }
            }

        # Write result to screen
        $DataVariable | Out-String | Write-Verbose 
}


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

    .LINK
    https://github.com/KnudsenMorten/AzLogDcrIngestPS

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

      [ 1 / 1 ] - Posting data to LogAnalytics table [ InvClientComputerOSInfoTESTV2_CL ] .... Please Wait !
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

                        $bearerToken = (invoke-restmethod -UseBasicParsing -Uri $uri -Method "Post" -Body $bodytoken -Headers $headers).access_token

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
                        If ( ($TotalDataLines -gt 1) -and (!($BatchAmount)) )
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
                                        # we are showing as first record is 1, but actually is is in record 0 - but we change it for gui purpose
                                        Write-host "  [ $($indexLoopFrom + 1)..$($indexLoopTo + 1) / $($TotalDataLines) ] - Posting data to LogAnalytics table [ $($TableName)_CL ] .... Please Wait !"
                                    }
                                ElseIf ($DataSendRemaining -eq 1)   # single record
                                    {
                                        Write-host "  [ $($indexLoopFrom + 1) / $($TotalDataLines) ] - Posting data to LogAnalytics table [ $($TableName)_CL ] .... Please Wait !"
                                    }

                                $uri = "$DceURI/dataCollectionRules/$DcrImmutableId/streams/$DcrStream"+"?api-version=2021-11-01-preview"
                            
                                # set encoding to UTF8
                                $JSON = [System.Text.Encoding]::UTF8.GetBytes($JSON)

                                $Result = invoke-webrequest -UseBasicParsing -Uri $uri -Method POST -Body $JSON -Headers $headers -ErrorAction SilentlyContinue
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
                    } #If ($DceURI -and $DcrImmutableId -and $DcrStream -and $Data)
        
            #return latest upload result
            return $Result
            
            Write-host ""
        }
}


Function Update-AzDataCollectionRuleDceEndpoint
{
 <#
    .SYNOPSIS
    Updates the DceEndpointUri of the Data Collection Rule

    .DESCRIPTION
    Used to change the Data Collection Endpoint in a Data Collection Rule

    .PARAMETER DcrResourceId
    This is resource id of the Data Collection Rule which should be changed

    .PARAMETER DceResourceId
    This is resource id of the Data Collection Endpoint to change to (target)

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

    # make sure the DCR & DCE actually exists
    $DcrName        = "dcr-clt1-InvClientComputerOSInfoTest5V2_CL"
    $DceNameTarget  = "dce-log-platform-management-client-demo1-p" 

    # Get details about DCR using Azure Resource Graph
    $AzDcrDetails      = Get-AzDcrDceDetails -DcrName $DcrName -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$verbose
    
    # check that it found a DCR
    $AzDcrDetails
    $DcrResourceId     = $AzDcrDetails[0]
    $DcrResourceId


    # check that it found a DCR
    $AzDceDetails      = Get-AzDcrDceDetails -DceName $DceNameTarget -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$verbose
    $AzDceDetails
    $DceResourceId     = $AzDceDetails[0]
    $DceResourceId

    # update data collection endpoint - getting details about DCE using Azure Resource Graph
    Update-AzDataCollectionRuleDceEndpoint -DcrResourceId $DcrResourceId -DceResourceId $DceResourceId -Verbose:$verbose

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 4797-byte response of content type application/json; charset=utf-8
    Updating DCE EndpointId for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest5V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4769-byte response of content type application/json; charset=utf-8

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
            [Parameter(mandatory)]
                [string]$DceResourceId,
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
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method GET -Headers $headers

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
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers

}



Function Update-AzDataCollectionRuleResetTransformKqlDefault
{
 <#
    .SYNOPSIS
    Updates the tranformKql parameter on an existing DCR - and resets it back to default

    .DESCRIPTION
    Used to set transformation back to default, where all data is being sent in - with needed TimeGenerated column

    .PARAMETER $DcrResourceId
    This is the resource id of the data collection rule

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
    $TableName                                       = 'InvClientComputerOSInfoTest5V2'   # must not contain _CL
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

    Write-Output ""
    Write-Output "Collecting Defender demo data"

    $DataVariable = Get-MpComputerStatus

    #-------------------------------------------------------------------------------------------
    # Preparing data structure
    #-------------------------------------------------------------------------------------------

    # convert CIM array to PSCustomObject and remove CIM class information
    $DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$verbose
    
    # add CollectionTime to existing array
    $DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$verbose

    # add Computer & UserLoggedOn info to existing array
    $DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name UserLoggedOn -Column2Data $UserLoggedOn -Verbose:$verbose

    # Validating/fixing schema data structure of source data
    $DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$verbose

    # Aligning data structure with schema (requirement for DCR)
    $DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$verbose

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


    # building global variable with all DCEs, which can be viewed by Log Ingestion app
    $global:AzDceDetails = Get-AzDceListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose
    
    # building global variable with all DCRs, which can be viewed by Log Ingestion app
    $global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose

    $AzDcrDceDetails = Get-AzDcrDceDetails -DcrName $DcrName `
                                           -AzAppId $LogIngestAppId -AzAppSecret $AzAppSecret -TenantId $TenantId -Verbose:$Verbose

    # make a DCR Event Log collection of security events - can be done through Sentinel
    $DcrResourceId = $AzDcrDceDetails[0]

    # check the schema for an column name where we want to retrieve data from
    Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose

    # set new transformation where we are adding a column AntivirusVersion with data from AMEngineVersion
    $transformKql = "source | extend TimeGenerated = now() | extend AntivirusVersion = AMEngineVersion"

    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$Verbose


    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 4735-byte response of content type application/json; charset=utf-8
    Updating transformKql for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest6V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4735-byte response of content type application/json; charset=utf-8

    # force a reset of the tranformation
    Update-AzDataCollectionRuleResetTransformKqlDefault -DcrResourceId $DcrResourceId -Verbose:$true

    #-------------------------------------------------------------------------------------------
    # Output
    #-------------------------------------------------------------------------------------------
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 4735-byte response of content type application/json; charset=utf-8
      Resetting transformKql to default for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-dcr-log-platform-management-client-demo1-p/providers/microsoft.insig
    hts/dataCollectionRules/dcr-clt1-InvClientComputerOSInfoTest6V2_CL
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 4691-byte response of content type application/json; charset=utf-8

  #>


    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
            [Parameter()]
                [string]$AzAppId,
            [Parameter()]
                [string]$AzAppSecret,
            [Parameter()]
                [string]$TenantId
         )

    #--------------------------------------------------------------------------
    # Variables
    #--------------------------------------------------------------------------

        $DefaultTransformKqlDcrLogIngestCustomLog = "source | extend TimeGenerated = now()"

    #--------------------------------------------------------------------------
    # Connection
    #--------------------------------------------------------------------------

        $Headers = Get-AzAccessTokenManagement -AzAppId $AzAppId `
                                               -AzAppSecret $AzAppSecret `
                                               -TenantId $TenantId -Verbose:$Verbose

    #--------------------------------------------------------------------------
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method GET -Headers $Headers

    #--------------------------------------------------------------------------
    # update payload object
    #--------------------------------------------------------------------------

        If ($DCR.properties.dataFlows[0].transformKql)
            {
                # changing value on existing property
                $DCR.properties.dataFlows[0].transformKql = $DefaultTransformKqlDcrLogIngestCustomLog
            }
        Else
            {
                # Adding new property to object
                $DCR.properties.dataFlows[0] | Add-Member -NotePropertyName transformKql -NotePropertyValue $transformKql -Force
            }

    #--------------------------------------------------------------------------
    # update existing DCR
    #--------------------------------------------------------------------------

        Write-host "  Resetting transformKql to default for DCR"
        Write-host $DcrResourceId

        # convert modified payload to JSON-format
        $DcrPayload = $Dcr | ConvertTo-Json -Depth 20

        # update changes to existing DCR
        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers
}


Function Update-AzDataCollectionRuleTransformKql
{
 <#
    .SYNOPSIS
    Updates the tranformKql parameter on an existing DCR with the provided parameter

    .DESCRIPTION
    Used to enable transformation on a data collection rule

    .PARAMETER $DcrResourceId
    This is the resource id of the data collection rule

    .PARAMETER $tranformKql
    This is tranformation query to use

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
    $Verbose = $true

    # make a DCR Event Log collection of security events - can be done through Sentinel
    $DcrResourceId = "/subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-ingest-exclude-security-eventid"

    # Remove transformation - send all data through pipeline
    $transformKql = "source"

    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$Verbose

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 1419-byte response of content type application/json; charset=utf-8
    Updating transformKql for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-i
    ngest-exclude-security-eventid
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 1419-byte response of content type application/json; charset=utf-8

    # Add transformation to exclude event 8002, 5058, 4662, 4688
    $transformKql = "source | where (EventID != 8002) and (EventID != 5058) and (EventID != 4662) and (EventID != 4688)"

    Update-AzDataCollectionRuleTransformKql -DcrResourceId $DcrResourceId -transformKql $transformKql -Verbose:$true

    # Output
    VERBOSE: GET with 0-byte payload
    VERBOSE: received 1511-byte response of content type application/json; charset=utf-8
    Updating transformKql for DCR
    /subscriptions/fce4f282-fcc6-43fb-94d8-bf1701b862c3/resourceGroups/rg-logworkspaces/providers/microsoft.insights/dataCollectionRules/dcr-i
    ngest-exclude-security-eventid
    VERBOSE: PUT with -1-byte payload
    VERBOSE: received 1511-byte response of content type application/json; charset=utf-8
	

 #>

    [CmdletBinding()]
    param(
            [Parameter(mandatory)]
                [string]$DcrResourceId,
            [Parameter(mandatory)]
                [string]$transformKql,
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
    # get existing DCR
    #--------------------------------------------------------------------------

        $DcrUri = "https://management.azure.com" + $DcrResourceId + "?api-version=2022-06-01"
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method GET -Headers $Headers

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
        $DCR = invoke-restmethod -UseBasicParsing -Uri $DcrUri -Method PUT -Body $DcrPayload -Headers $Headers

}



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
# MIIXHgYJKoZIhvcNAQcCoIIXDzCCFwsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDI2hKA9bskWWLe
# FmvCJD+eNJMSG1+HuFH/95qyMFy6BqCCE1kwggVyMIIDWqADAgECAhB2U/6sdUZI
# k/Xl10pIOk74MA0GCSqGSIb3DQEBDAUAMFMxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENvZGUgU2ln
# bmluZyBSb290IFI0NTAeFw0yMDAzMTgwMDAwMDBaFw00NTAzMTgwMDAwMDBaMFMx
# CzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQD
# EyBHbG9iYWxTaWduIENvZGUgU2lnbmluZyBSb290IFI0NTCCAiIwDQYJKoZIhvcN
# AQEBBQADggIPADCCAgoCggIBALYtxTDdeuirkD0DcrA6S5kWYbLl/6VnHTcc5X7s
# k4OqhPWjQ5uYRYq4Y1ddmwCIBCXp+GiSS4LYS8lKA/Oof2qPimEnvaFE0P31PyLC
# o0+RjbMFsiiCkV37WYgFC5cGwpj4LKczJO5QOkHM8KCwex1N0qhYOJbp3/kbkbuL
# ECzSx0Mdogl0oYCve+YzCgxZa4689Ktal3t/rlX7hPCA/oRM1+K6vcR1oW+9YRB0
# RLKYB+J0q/9o3GwmPukf5eAEh60w0wyNA3xVuBZwXCR4ICXrZ2eIq7pONJhrcBHe
# OMrUvqHAnOHfHgIB2DvhZ0OEts/8dLcvhKO/ugk3PWdssUVcGWGrQYP1rB3rdw1G
# R3POv72Vle2dK4gQ/vpY6KdX4bPPqFrpByWbEsSegHI9k9yMlN87ROYmgPzSwwPw
# jAzSRdYu54+YnuYE7kJuZ35CFnFi5wT5YMZkobacgSFOK8ZtaJSGxpl0c2cxepHy
# 1Ix5bnymu35Gb03FhRIrz5oiRAiohTfOB2FXBhcSJMDEMXOhmDVXR34QOkXZLaRR
# kJipoAc3xGUaqhxrFnf3p5fsPxkwmW8x++pAsufSxPrJ0PBQdnRZ+o1tFzK++Ol+
# A/Tnh3Wa1EqRLIUDEwIrQoDyiWo2z8hMoM6e+MuNrRan097VmxinxpI68YJj8S4O
# JGTfAgMBAAGjQjBAMA4GA1UdDwEB/wQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB0G
# A1UdDgQWBBQfAL9GgAr8eDm3pbRD2VZQu86WOzANBgkqhkiG9w0BAQwFAAOCAgEA
# Xiu6dJc0RF92SChAhJPuAW7pobPWgCXme+S8CZE9D/x2rdfUMCC7j2DQkdYc8pzv
# eBorlDICwSSWUlIC0PPR/PKbOW6Z4R+OQ0F9mh5byV2ahPwm5ofzdHImraQb2T07
# alKgPAkeLx57szO0Rcf3rLGvk2Ctdq64shV464Nq6//bRqsk5e4C+pAfWcAvXda3
# XaRcELdyU/hBTsz6eBolSsr+hWJDYcO0N6qB0vTWOg+9jVl+MEfeK2vnIVAzX9Rn
# m9S4Z588J5kD/4VDjnMSyiDN6GHVsWbcF9Y5bQ/bzyM3oYKJThxrP9agzaoHnT5C
# JqrXDO76R78aUn7RdYHTyYpiF21PiKAhoCY+r23ZYjAf6Zgorm6N1Y5McmaTgI0q
# 41XHYGeQQlZcIlEPs9xOOe5N3dkdeBBUO27Ql28DtR6yI3PGErKaZND8lYUkqP/f
# obDckUCu3wkzq7ndkrfxzJF0O2nrZ5cbkL/nx6BvcbtXv7ePWu16QGoWzYCELS/h
# AtQklEOzFfwMKxv9cW/8y7x1Fzpeg9LJsy8b1ZyNf1T+fn7kVqOHp53hWVKUQY9t
# W76GlZr/GnbdQNJRSnC0HzNjI3c/7CceWeQIh+00gkoPP/6gHcH1Z3NFhnj0qinp
# J4fGGdvGExTDOUmHTaCX4GUT9Z13Vunas1jHOvLAzYIwggbmMIIEzqADAgECAhB3
# vQ4DobcI+FSrBnIQ2QRHMA0GCSqGSIb3DQEBCwUAMFMxCzAJBgNVBAYTAkJFMRkw
# FwYDVQQKExBHbG9iYWxTaWduIG52LXNhMSkwJwYDVQQDEyBHbG9iYWxTaWduIENv
# ZGUgU2lnbmluZyBSb290IFI0NTAeFw0yMDA3MjgwMDAwMDBaFw0zMDA3MjgwMDAw
# MDBaMFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8w
# LQYDVQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMDCC
# AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANZCTfnjT8Yj9GwdgaYw90g9
# z9DljeUgIpYHRDVdBs8PHXBg5iZU+lMjYAKoXwIC947Jbj2peAW9jvVPGSSZfM8R
# Fpsfe2vSo3toZXer2LEsP9NyBjJcW6xQZywlTVYGNvzBYkx9fYYWlZpdVLpQ0LB/
# okQZ6dZubD4Twp8R1F80W1FoMWMK+FvQ3rpZXzGviWg4QD4I6FNnTmO2IY7v3Y2F
# QVWeHLw33JWgxHGnHxulSW4KIFl+iaNYFZcAJWnf3sJqUGVOU/troZ8YHooOX1Re
# veBbz/IMBNLeCKEQJvey83ouwo6WwT/Opdr0WSiMN2WhMZYLjqR2dxVJhGaCJedD
# CndSsZlRQv+hst2c0twY2cGGqUAdQZdihryo/6LHYxcG/WZ6NpQBIIl4H5D0e6lS
# TmpPVAYqgK+ex1BC+mUK4wH0sW6sDqjjgRmoOMieAyiGpHSnR5V+cloqexVqHMRp
# 5rC+QBmZy9J9VU4inBDgoVvDsy56i8Te8UsfjCh5MEV/bBO2PSz/LUqKKuwoDy3K
# 1JyYikptWjYsL9+6y+JBSgh3GIitNWGUEvOkcuvuNp6nUSeRPPeiGsz8h+WX4VGH
# aekizIPAtw9FbAfhQ0/UjErOz2OxtaQQevkNDCiwazT+IWgnb+z4+iaEW3VCzYkm
# eVmda6tjcWKQJQ0IIPH/AgMBAAGjggGuMIIBqjAOBgNVHQ8BAf8EBAMCAYYwEwYD
# VR0lBAwwCgYIKwYBBQUHAwMwEgYDVR0TAQH/BAgwBgEB/wIBADAdBgNVHQ4EFgQU
# 2rONwCSQo2t30wygWd0hZ2R2C3gwHwYDVR0jBBgwFoAUHwC/RoAK/Hg5t6W0Q9lW
# ULvOljswgZMGCCsGAQUFBwEBBIGGMIGDMDkGCCsGAQUFBzABhi1odHRwOi8vb2Nz
# cC5nbG9iYWxzaWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUwRgYIKwYBBQUHMAKG
# Omh0dHA6Ly9zZWN1cmUuZ2xvYmFsc2lnbi5jb20vY2FjZXJ0L2NvZGVzaWduaW5n
# cm9vdHI0NS5jcnQwQQYDVR0fBDowODA2oDSgMoYwaHR0cDovL2NybC5nbG9iYWxz
# aWduLmNvbS9jb2Rlc2lnbmluZ3Jvb3RyNDUuY3JsMFYGA1UdIARPME0wQQYJKwYB
# BAGgMgEyMDQwMgYIKwYBBQUHAgEWJmh0dHBzOi8vd3d3Lmdsb2JhbHNpZ24uY29t
# L3JlcG9zaXRvcnkvMAgGBmeBDAEEATANBgkqhkiG9w0BAQsFAAOCAgEACIhyJsav
# +qxfBsCqjJDa0LLAopf/bhMyFlT9PvQwEZ+PmPmbUt3yohbu2XiVppp8YbgEtfjr
# y/RhETP2ZSW3EUKL2Glux/+VtIFDqX6uv4LWTcwRo4NxahBeGQWn52x/VvSoXMNO
# Ca1Za7j5fqUuuPzeDsKg+7AE1BMbxyepuaotMTvPRkyd60zsvC6c8YejfzhpX0FA
# Z/ZTfepB7449+6nUEThG3zzr9s0ivRPN8OHm5TOgvjzkeNUbzCDyMHOwIhz2hNab
# XAAC4ShSS/8SS0Dq7rAaBgaehObn8NuERvtz2StCtslXNMcWwKbrIbmqDvf+28rr
# vBfLuGfr4z5P26mUhmRVyQkKwNkEcUoRS1pkw7x4eK1MRyZlB5nVzTZgoTNTs/Z7
# KtWJQDxxpav4mVn945uSS90FvQsMeAYrz1PYvRKaWyeGhT+RvuB4gHNU36cdZytq
# tq5NiYAkCFJwUPMB/0SuL5rg4UkI4eFb1zjRngqKnZQnm8qjudviNmrjb7lYYuA2
# eDYB+sGniXomU6Ncu9Ky64rLYwgv/h7zViniNZvY/+mlvW1LWSyJLC9Su7UpkNpD
# R7xy3bzZv4DB3LCrtEsdWDY3ZOub4YUXmimi/eYI0pL/oPh84emn0TCOXyZQK8ei
# 4pd3iu/YTT4m65lAYPM8Zwy2CHIpNVOBNNwwggb1MIIE3aADAgECAgx5Y9ljauM7
# cdkFAm4wDQYJKoZIhvcNAQELBQAwWTELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEds
# b2JhbFNpZ24gbnYtc2ExLzAtBgNVBAMTJkdsb2JhbFNpZ24gR0NDIFI0NSBDb2Rl
# U2lnbmluZyBDQSAyMDIwMB4XDTIzMDMyNzEwMjEzNFoXDTI2MDMyMzE2MTgxOFow
# YzELMAkGA1UEBhMCREsxEDAOBgNVBAcTB0tvbGRpbmcxEDAOBgNVBAoTBzJsaW5r
# SVQxEDAOBgNVBAMTBzJsaW5rSVQxHjAcBgkqhkiG9w0BCQEWD21va0AybGlua2l0
# Lm5ldDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBAMykjWtM6hY5IRPe
# VIVB+yX+3zcMJQR2gjTZ81LnGVRE94Zk2GLFAwquGYWt1shoTHTV5j6Ef2AXYBDV
# kNruisJVJ17UsMGdsU8upwdZblFbLNzLw+qBXVC/OUVua9M0cub7CfUNkn/Won4D
# 7i41QyuDXdZFOIfRhZ3qnCYCJCSgYLoUXAS6xei2tPkkk1w8aXEFxybyy7eRqQjk
# HqIS5N4qH3YQkz+SbSlz/yj6mD65H5/Ts+lZxX2xL/8lgJItpdaJx+tarprv/tT+
# +n9a13P53YNzCWOmyhd376+7DMXxxSzT24kq13Ks3xnUPGoWUx2UPRnJHjTWoBfg
# Y7Zd3MffrdO0QEoDC9X5F5boh6oankVSOdSPRFns085KI+vkbt3bdG62MIeUbNtS
# v7mZBX8gcYv0szlo0ey7bbOJWoiZFT2fB+pBVvxDhpYP0/3aFveM1wfhshaJBhxx
# /2GCswYYBHH7B3+8j4BT8N8S030q4snys2Qt9tdFIHvSV7lIw/yorT1WM1cr+Lqo
# 74eR+Hi982db0k68p2BGdCOY0QhhaNqxufwbK+gVWrQY57GIX/1cUrBt0akMsli2
# 19xVmUGhIw85ZF7wcQplhslbUxyNUilY+c93q1bsIFjaOnjjvo56g+kyKICm5zsG
# FQLRVaXUSLY+i8NSiH8fd64etaptAgMBAAGjggGxMIIBrTAOBgNVHQ8BAf8EBAMC
# B4AwgZsGCCsGAQUFBwEBBIGOMIGLMEoGCCsGAQUFBzAChj5odHRwOi8vc2VjdXJl
# Lmdsb2JhbHNpZ24uY29tL2NhY2VydC9nc2djY3I0NWNvZGVzaWduY2EyMDIwLmNy
# dDA9BggrBgEFBQcwAYYxaHR0cDovL29jc3AuZ2xvYmFsc2lnbi5jb20vZ3NnY2Ny
# NDVjb2Rlc2lnbmNhMjAyMDBWBgNVHSAETzBNMEEGCSsGAQQBoDIBMjA0MDIGCCsG
# AQUFBwIBFiZodHRwczovL3d3dy5nbG9iYWxzaWduLmNvbS9yZXBvc2l0b3J5LzAI
# BgZngQwBBAEwCQYDVR0TBAIwADBFBgNVHR8EPjA8MDqgOKA2hjRodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzZ2NjcjQ1Y29kZXNpZ25jYTIwMjAuY3JsMBMGA1Ud
# JQQMMAoGCCsGAQUFBwMDMB8GA1UdIwQYMBaAFNqzjcAkkKNrd9MMoFndIWdkdgt4
# MB0GA1UdDgQWBBQxxpY2q5yrKa7VFODTZhTfPKmyyTANBgkqhkiG9w0BAQsFAAOC
# AgEAe38NgZR4IV9u264/n/jiWlHbBu847j1vpN6dovxMvdUQZ780eH3JzcvG8fo9
# 1uO1iDIZksSigiB+d8Sj5Yvh+oXlfYEffjIQCwcIlWNciOzWYZzl9qPHXgdTnaIu
# JA5cR846TepQLVMXc1Yb72Z7OGjldmRIxGjRimDsmzY+TdTu15lF4IkUj0VJhr8F
# PYOdEVZVOXHtPmUjPqsq9M7WpALYbc0pUawcy0FOOwXqzaCk7O3vMXej4Oycm6RB
# GfRH3JPOCvH2ddiIfPq2Lce4nhTuLsgumBJE2vOalVddIfTBjE9PpMub15lHyp1m
# fW0ZJvXOghPvRqufMT3SjPTHt6PV8LwhQD8BiGSZ9rp94js4xTnGexSOFKLLMxWE
# PTr5EPe3kmtspGgKCqLEZvsMYz7JlWNuaHBy+vdQZWV3376luwV4IHfGT+1wxe0E
# 90dMRI+9SNIKkVvKV3FUtToZUh3Np4cCIHJLQ1eslXFzIJa6wrjVsnWM/3OyedpQ
# JERGNYXlVmxdgGFjrY1I6UWII0Y1iZW3t+JvhXosUaha8i/YSxaDH+5H/Klad2OZ
# Xq4Eg39QxkCELbmJmSU0sUYNnl0JTEu6jJY9UJMFikzf5s3p2ZuKdyMbRgN5GNNV
# 883meI/X5KVHBJDG1epigMer7fFXMVZUGoI12iIz/gOolQExggMbMIIDFwIBATBp
# MFkxCzAJBgNVBAYTAkJFMRkwFwYDVQQKExBHbG9iYWxTaWduIG52LXNhMS8wLQYD
# VQQDEyZHbG9iYWxTaWduIEdDQyBSNDUgQ29kZVNpZ25pbmcgQ0EgMjAyMAIMeWPZ
# Y2rjO3HZBQJuMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFJNT3xwe/8gCDO+fsiNils2
# TLofOFss5o4sX9GmaP59MA0GCSqGSIb3DQEBAQUABIICAMCoGf6EfoXN0PGhrPt/
# W2Xv280QDOPvun610UeUa+07Ot0uooQlbtKlgsx0doVroOnC0uzKHPDnQo3341VC
# euroBvrGAcEdjwgkhL2AXdNX3/IrxzO0A7JDKICI73JQMR1yFxNqlEWIEhjxhJkE
# HLTGyOayYaQ3c+Yw+7y9cN5E++77IpFBQftizK5i2d/6VFXMo5iDcD5/UqhRk/eT
# E1H881jR01OdYNcYo/2XDuVqajuUESyRipAP3nWN2QQsXBb3kU/TzrV9ozzTISk5
# BD/0e7XyPlqyojbuIhh1BqLTqyDNHoWkROp5mmIcHW8qdZl8OwEDY39lWHFgaohW
# +CF9RPxZ+kyfShWRWcsoWkvU9bI6/w2GiwklPU8TL0L86EsyKDrri0xM/qJPw4rn
# 7j3duNoIx1V8WrWDafO9QeOrvI9r1AvdzTD8g6ca/GYd+3ssIpBsf67M8o63QatP
# gk9wwx6oeb0P+N0Bkq1PY8HPzfdQJ0IN/iCDszRvo2bUNMsoSpWjMmXogVbN2h2Q
# zvc7NFZ+HDCd+B/91pJOv84W+q9/fVO4YOBVj8rlDTrffZcVrR1dWOrDwCXXPf8M
# ced4QhofpjFbXotxdCZ4NPAo0YrKww18fae4W+87vCXUiqUSEuHOBYAiMULVkao4
# 4yz43tDFKpV/wWyjBH3jmN7c
# SIG # End signature block
