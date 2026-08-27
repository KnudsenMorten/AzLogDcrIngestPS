Function Get-ObjectSchemaAsArray {
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

        #--------------------------------------------------------------------------------------
        # v1.7.0 (perf). The original inferred the schema by running
        #     $Entry | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Get-Member
        # on EVERY row, and then testing each column with
        #     $Column.Name -notin $SchemaArrayLogAnalyticsTableFormat.name
        # which re-projects a growing array once per column - O(rows x cols^2). On a
        # 6,339-row x 299-column upload that is ~567M comparisons plus 6,339 JSON round-trips.
        #
        # Two changes, no semantic difference:
        #   1. a HashSet answers "have I seen this column?" in O(1) instead of rescanning;
        #   2. the JSON round-trip - which is what infers the TYPE - now runs only for rows that
        #      actually introduce a column not yet seen. Because the original took each column
        #      type from the FIRST row that carried it and skipped it forever after, restricting
        #      the round-trip to those same rows yields identical output. In practice only the
        #      first row (plus any row with a genuinely new column) pays for it.
        #--------------------------------------------------------------------------------------

        $SchemaArrayLogAnalyticsTableFormat = New-Object 'System.Collections.Generic.List[object]'
        $SchemaArrayDcrFormat               = New-Object 'System.Collections.Generic.List[object]'

        # OrdinalIgnoreCase matches the case-insensitive -notin comparison it replaces
        $SeenColumnNames = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

        # Requirement - Add TimeGenerated to array (table format only, exactly as before)
        [void]$SeenColumnNames.Add("TimeGenerated")
        [void]$SchemaArrayLogAnalyticsTableFormat.Add( [PSCustomObject]@{
                                                     name        = "TimeGenerated"
                                                     type        = "datetime"
                                                     description = ""
                                               } )

        # Loop source object and build hash for table schema
        ForEach ($Entry in $Data)
            {
                # cheap pre-check: does this row introduce anything new at all?
                $EntryHasNewColumn = $false
                ForEach ($Property in $Entry.PSObject.Properties)
                    {
                        If (-not $SeenColumnNames.Contains($Property.Name)) { $EntryHasNewColumn = $true; Break }
                    }
                If (-not $EntryHasNewColumn) { Continue }

                $ObjColumns = $Entry | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Get-Member -MemberType NoteProperty
                ForEach ($Column in $ObjColumns)
                    {
                        If ($SeenColumnNames.Contains($Column.Name)) { Continue }

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

                        [void]$SeenColumnNames.Add($Column.Name)

                        [void]$SchemaArrayLogAnalyticsTableFormat.Add( [PSCustomObject]@{
                                                                   name        = $Column.Name
                                                                   type        = $ObjType
                                                                   description = ""
                                                                } )

                        [void]$SchemaArrayDcrFormat.Add( [PSCustomObject]@{
                                                      name        = $Column.Name
                                                      type        = $ObjType
                                                  } )
                    }
            }

            If ($ReturnType -eq "Table")
            {
                # Return schema format for LogAnalytics table
                Return $SchemaArrayLogAnalyticsTableFormat.ToArray()
            }
        ElseIf ($ReturnType -eq "DCR")
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat.ToArray()
            }
        Else
            {
                # Return schema format for DCR
                Return $SchemaArrayDcrFormat.ToArray()
            }
}

