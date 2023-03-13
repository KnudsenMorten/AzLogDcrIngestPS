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
