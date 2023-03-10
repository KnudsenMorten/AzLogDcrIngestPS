# AzLogDcrIngestPS
AzLogDcrIngestPS

**Get-AzAccessTokenManagement**

.SYNOPSIS
Get access token for connecting management.azure.com - used for REST API connectivity

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Can be used under current connected user - or by Azure app connectivity with secret

.PARAMETER AzAppId
This is the Azure app id og an app with Contributor permissions in LogAnalytics + Resource Group for DCRs

.PARAMETER AzAppSecret
This is the secret of the Azure app

.PARAMETER TenantId
This is the Azure AD tenant id

.INPUTS
None. You cannot pipe objects

.OUTPUTS
JSON-header to use in invoke-webrequest / invoke-restmethod commands

.EXAMPLE
PS> $Headers = Get-AzAccessTokenManagement -AzAppId <id> -AzAppSecret <secret> -TenantId <id>

**CreateUpdate-AzLogAnalyticsCustomLogTableDcr**

 .SYNOPSIS
Create or Update Azure LogAnalytics Custom Log table - used together with Data Collection Rules (DCR)
for Log Ingestion API upload to LogAnalytics

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Uses schema based on source object

.PARAMETER Tablename
Specifies the table name in LogAnalytics

.PARAMETER SchemaSourceObject
This is the schema in hash table format coming from the source object

.PARAMETER AzLogWorkspaceResourceId
This is the Loganaytics Resource Id

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

.EXAMPLE
PS> CreateUpdate-AzLogAnalyticsCustomLogTableDcr

**CreateUpdate-AzDataCollectionRuleLogIngestCustomLog**

.SYNOPSIS
Create or Update Azure Data Collection Rule (DCR) used for log ingestion to Azure LogAnalytics using
Log Ingestion API

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Uses schema based on source object

.PARAMETER Tablename
Specifies the table name in LogAnalytics

.PARAMETER SchemaSourceObject
This is the schema in hash table format coming from the source object

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

Variable $global:AzDcrDetails can be build before calling this cmdlet using this syntax
$global:AzDcrDetails = Get-AzDcrListAll -AzAppId $LogIngestAppId -AzAppSecret $LogIngestAppSecret -TenantId $TenantId -Verbose:$Verbose -Verbose:$Verbose

.PARAMETER TableName
This is tablename of the LogAnalytics table (and is also used in the DCR naming)

.PARAMETER AzDcrSetLogIngestApiAppPermissionsDcrLevel
Choose TRUE if you want to set Monitoring Publishing Contributor permissions on DCR level
Choose FALSE if you would like to use inherited permissions from the resource group level (recommended)

.PARAMETER LogIngestServicePricipleObjectId
This is the object id of the Azure App service-principal
 - NOTE: Not the object id of the Azure app, but Object Id of the service principal (!)

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

.EXAMPLE
PS> CreateUpdate-AzDataCollectionRuleLogIngestCustomLog

.NOTES

**Update-AzDataCollectionRuleResetTransformKqlDefault**

.SYNOPSIS
Updates the tranformKql parameter on an existing DCR - and resets it back to default

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Update-AzDataCollectionRuleResetTransformKqlDefault

.NOTES

**Update-AzDataCollectionRuleTransformKql**

.SYNOPSIS
Updates the tranformKql parameter on an existing DCR with the provided parameter

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Update-AzDataCollectionRuleTransformKql

**Update-AzDataCollectionRuleLogAnalyticsCustomLogTableSchema**

.SYNOPSIS
Updates the schema of Azure Loganalytics table + Azure Data Collection Rule - based on source object schema

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Used to ensure DCR and LogAnalytics table can accept the structure/schema coming from the source object

.PARAMETER SchemaSourceObject
This is the schema in hash table format coming from the source object

.PARAMETER Tablename
Specifies the table name in LogAnalytics

.PARAMETER DcrResourceId
This is resource id of the Data Collection Rule

.PARAMETER AzLogWorkspaceResourceId
This is the Loganaytics Resource Id

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

.EXAMPLE
PS> Update-AzDataCollectionRuleLogAnalyticsCustomLogTableSchema

**Update-AzDataCollectionRuleDceEndpoint**

.SYNOPSIS
Updates the DceEndpointUri of the Data Collection Rule

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Update-AzDataCollectionRuleDceEndpoint

**Delete-AzLogAnalyticsCustomLogTables**
.SYNOPSIS
Deletes the Azure Loganalytics defined in like-format, so you can fast clean-up for example after demo or testing

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Delete-AzLogAnalyticsCustomLogTables -TableLike *demo* will delete all tables with the word demo in it

**Delete-AzDataCollectionRules**
.SYNOPSIS
Deletes the Azure Loganalytics defined in like-format, so you can fast clean-up for example after demo or testing

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Delete-AzDataCollectionRules -DcrNameLike *demo* will delete all DCRs with the word demo in it

**Get-AzDcrDceDetails**
.SYNOPSIS
Retrieves information about data collection rules and data collection endpoints - using Azure Resource Graph

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Used to retrieve information about data collection rules and data collection endpoints - using Azure Resource Graph
Used by other functions which are looking for DCR/DCE by name

.PARAMETER DcrName
Here you can put in the DCR name you want to find

.PARAMETER DceName
Here you can put in the DCE name you want to find

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

.EXAMPLE
PS> Get-AzDcrDceDetails

**Post-AzLogAnalyticsLogIngestCustomLogDcrDce**
.SYNOPSIS
Send data to LogAnalytics using Log Ingestion API and Data Collection Rule

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> Get-AzDcrDceDetails

**ValidateFix-AzLogAnalyticsTableSchemaColumnNames**
.SYNOPSIS
Validates the column names in the schema are valid according the requirement for LogAnalytics tables
Fixes any issues by rebuild the source object

Developed by Morten Knudsen, Microsoft MVP

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

.EXAMPLE
PS> ValidateFix-AzLogAnalyticsTableSchemaColumnNames

**Build-DataArrayToAlignWithSchema**
.SYNOPSIS
Rebuilds the source object to match modified schema structure - used after usage of ValidateFix-AzLogAnalyticsTableSchemaColumnNames

Developed by Morten Knudsen, Microsoft MVP

.DESCRIPTION
Builds new PSCustomObject object

.PARAMETER Data
This is the data array

.INPUTS
None. You cannot pipe objects

.OUTPUTS
Updated $DataVariable with valid column names

.EXAMPLE
PS> Build-DataArrayToAlignWithSchema

 **Get-AzLogAnalyticsTableAzDataCollectionRuleStatus**
 
 **Add-ColumnDataToAllEntriesInArray**
 
 **Add-CollectionTimeToAllEntriesInArray**
 
 **Convert-CimArrayToObjectFixStructure**
 
 **Convert-PSArrayToObjectFixStructure**
 
 **Get-ObjectSchemaAsArray**
 
 **Get-ObjectSchemaAsHash**
 
 **Filter-ObjectExcludeProperty**
 
 **Get-AzDcrListAll**
 
 Get-AzDceListAll
 
 Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output
 
 CheckCreateUpdate-TableDcr-Structure
