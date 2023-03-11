# AzLogDcrIngestPS
I am realy happy to announce my Powershell module, **AzLogDcrIngestPS**

## Background for building this Powershell module
For the last 5 years, I have been using the Log Analytics Data Collector API - also referred to 'Azure Monitor HTTP Data Collector API' - or my short name for it "MMA-method"

I have using the API with my Powershell scripts to upload 'tons' of custom data into Azure LogAnalytics. On top, I provided 35 Azure dashboards, that gives me (and my customers) great insight to the health and security of their environment.

![Flow-MMA](img/Concept-legacy-mma.png)

Moving forward, Microsoft has introduced the concept of Azure Data Collection Rules (DCRs), which I have been really fan of.

## Introduction of the new method using Azure Data Collection Rules (DCRs)

### Data In to Data Collection Rules pipeline - or in short DCR-pipeline

Currently, Microsoft supports many sources of data coming through DCR pipeline - outlined in the table below:
|Collection source|Technologies required|Flow|
|:----------------|:--------------------|:---|
|Performance<br>Eventlog<br>Syslog|AMA<br>DCR<br>|1. AMA<br>2. DCR ingestion pipeline<br>3. LogAnalytics|

![Flow-DCR](img/Concept-dcr-pipeline.png)

### Transformation using DCR pipeline (data transformation)

|Category | Details |
|:--------|:--------|
| Remove sensitive data|You may have a data source that sends information you don’t want stored for privacy or compliancy reasons<br/><br/>**Filter sensitive information**. Filter out entire rows or just particular columns that contain sensitive information<br/><br/>**Obfuscate sensitive information**. For example, you might replace digits with a common character in an IP address or telephone number.|
|Enrich data with additional or calculated information|Use a transformation to add information to data that provides business context or simplifies querying the data later.<br/><br/>**Add a column with additional information**. For example, you might add a column identifying whether an IP address in another column is internal or external.<br/><br/>**Add business specific information**. For example, you might add a column indicating a company division based on location information in other columns.|
|Reduce data costs|Since you’re charged ingestion cost for any data sent to a Log Analytics workspace, you want to filter out any data that you don’t require to reduce your costs.<br/><br/>**Remove entire rows**. For example, you might have a diagnostic setting to collect resource logs from a particular resource but not require all of the log entries that it generates. Create a transformation that filters out records that match a certain criteria.<br/><br/>**Remove a column from each row**. For example, your data may include columns with data that’s redundant or has minimal value. Create a transformation that filters out columns that aren’t required.<br/><br/>**Parse important data from a column**. You may have a table with valuable data buried in a particular column. Use a transformation to parse the valuable data into a new column and remove the original.<br/><br/>Examples of where data-transformation is useful:<br/><br/>We want to remove specific security-events from a server, which are making lots of ”noise” in our logs due to a misconfiguration or error and it is impossible to fix it.<br/><br/>We want to remove security events, which we might show with a high amount, but we want to filter it out like kerberos computer-logon traffic.|

Sample of Kusto query
| Kusto Query|Purpose|Transformation syntax for DCR 'transformKql' command|
|:-----------|:------|:---------------------------------------------------|
|SecurityEvent \| where (EventID != 12345)|Remove events with EventID 12345 in SecurityEvent table|source \| where (EventID != 12345)|
|SecurityEvent \| where (EventID != 8002) and (EventID != 5058) and (EventID != 4662)|Remove events with EventId 4662,5058,8002 in SecurityEvent table|source \| where (EventID != 8002) and (EventID != 5058) and (EventID != 4662)|
|Event \| where ( (EventID != 10016 and EventLog == “Application”)  )|Remove events with EventID 10016, if source is Application log|source \| where ( (EventID != 10016 and EventLog == “Application”)  )|
|Inventory_CL \| extend TimeGenerated = now()|Add new column TimeGenerated with the actual time (now), when data is coming in|source \| extend TimeGenerated = now()|


![Transformation](img/Concept-transformation-ama.png)

![Transformation](img/Concept-transformation-log-ingest.png)

![Transformation](img/Concept-transformation-workspace.png)

More information about the topic on my blog - [How to do data transformation with Azure LogAnalytics – to enrich information, optimize cost, remove sensitive data?](https://mortenknudsen.net/?p=73)


### Transformation using DCR pipeline (destinations, data out)
As an alternative to doing data transformation, DCRs does also support transforming the destination of the data.

Currently, DCRs support the following destinations:

You should expect to see more 'destinations' in the future, where DCRs can send data to. I am really excited about the future :-)


### Data Out of DCR pipeline

The Log Ingestion API replaces the legacy method called Log Analytics Data Collector API (or Azure Monitor HTTP Data Collector API or my short name for it "MMA-method")

> Don't let yourself be confused, when you are searching the internet for 'Azure Monitor HTTP Data Collector' and it comes up saying it is in **public preview**. It is <ins>still the legacy API</ins> which will be **replaced** by Log Ingestion API.

> Product team quotes: “Data Collector API was never officially released or considered "complete”. We are going to update Data Collector API documentation as part of its deprecation cycle”


## Introduction
Core features of Powershell module **AzLogDcrIngestPS**:
* create/update the DCRs and tables automatically - based on the source object schema
* validate the schema for naming convention issues. If exist found, it will mitigate the issues
* update schema of DCRs and tables, if the structure of the source object changes
* auto-fix if something goes wrong with a DCR or table
* can remove data from the source object, if there are colums of data you don't want to send
* can convert source objects based on CIM or PS objects into PSCustomObjects/array
* can add relevant information to each record like UserLoggedOn, Computer, CollectionTime

You can download latest version here:

[AzLogDcringestPS (Github)](https://github.com/KnudsenMorten/AzLogDcrIngestPS)

[AzLogDcringestPS (Powershell Gallery)](https://www.powershellgallery.com/packages/AzLogDcrIngestPS)



ClientInspector uses several functions within the Powershell module, **AzLogDcIngestPS**, to handle source data adjustsments to **remove "noice" in data**, to **remove prohibited colums in tables/DCR** - and support needs for **transparency** with extra insight like **UserLoggedOn**, **CollectionTime**, **Computer**:

<details>
  <summary>Examples of how to use functions Convert-CimArrayToObjectFixStructure, Add-CollectionTimeToAllEntriesInArray, Add-ColumnDataToAllEntriesInArray, ValidateFix-AzLogAnalyticsTableSchemaColumnNames, Build-DataArrayToAlignWithSchema, Filter-ObjectExcludeProperty</summary>

```js
#-------------------------------------------------------------------------------------------
# Collecting data (in)
#-------------------------------------------------------------------------------------------
	
Write-Output ""
Write-Output "Collecting Bios information ... Please Wait !"

$DataVariable = Get-CimInstance -ClassName Win32_BIOS

#-------------------------------------------------------------------------------------------
# Preparing data structure
#-------------------------------------------------------------------------------------------

# convert CIM array to PSCustomObject and remove CIM class information
$DataVariable = Convert-CimArrayToObjectFixStructure -data $DataVariable -Verbose:$Verbose

# add CollectionTime to existing array
$DataVariable = Add-CollectionTimeToAllEntriesInArray -Data $DataVariable -Verbose:$Verbose

# add Computer & UserLoggedOn info to existing array
$DataVariable = Add-ColumnDataToAllEntriesInArray -Data $DataVariable -Column1Name Computer -Column1Data $Env:ComputerName -Column2Name UserLoggedOn -Column2Data $UserLoggedOn -Verbose:$Verbose

# Remove unnecessary columns in schema
$DataVariable = Filter-ObjectExcludeProperty -Data $DataVariable -ExcludeProperty __*,SystemProperties,Scope,Qualifiers,Properties,ClassPath,Class,Derivation,Dynasty,Genus,Namespace,Path,Property_Count,RelPath,Server,Superclass -Verbose:$Verbose

# Validating/fixing schema data structure of source data
$DataVariable = ValidateFix-AzLogAnalyticsTableSchemaColumnNames -Data $DataVariable -Verbose:$Verbose

# Aligning data structure with schema (requirement for DCR)
$DataVariable = Build-DataArrayToAlignWithSchema -Data $DataVariable -Verbose:$Verbose
````

You can verify the source object by running this command
````
# Get insight about the schema structure of an object BEFORE changes. Command is only needed to verify columns in schema
Get-ObjectSchemaAsArray -Data $DataVariable -Verbose:$Verbose
````
</details>



# Deepdive of the architecture of AzLogDcrIngestPS
The following section of information comes from [Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview)

I have spent a significant time understanding the technology and reporting my findings in close cooperation with the **Azure Pipeline product-team (reponsible for Log Ingestion API integration against Azure LogAnalytics)** - and ** Azure Data Collection Rules product-team**.

## Introduction to Log Ingestion API

The Log Ingestion API replaces the legacy method called Log Analytics Data Collector API (or Azure Monitor HTTP Data Collector API or my short name for it "MMA-method")

> Don't let yourself be confused, when you are searching the internet for 'Azure Monitor HTTP Data Collector' and it comes up saying it is in **public preview**. It is <ins>still the legacy API</ins> which will be **replaced** by Log Ingestion API.

> Product team quotes: “Data Collector API was never officially released or considered "complete”. We are going to update Data Collector API documentation as part of its deprecation cycle”

The Logs Ingestion API in Azure Monitor lets you send data to a Log Analytics workspace from any REST API client. 

By using this API, you can send data from almost any source to supported Azure tables or to custom tables that you create. 

You can even extend the schema of Azure tables with custom columns.

The Logs Ingestion API was previously referred to as the custom logs API.

## Dataflow
The endpoint application sends data to a data collection endpoint (DCE), which is a unique connection point for your subscription. 

The payload of your API call includes the source data formatted in JSON. 

The call:

1. Specifies a data collection rule (DCR) that understands the format of the source data.
2. Potentially filters and transforms it for the target table.
3. Directs it to a specific table in a specific workspace.

You can modify the target table and workspace by modifying the DCR without any change to the REST API call or source data.

![Flow](img/flow.png)

### Migration
To migrate solutions from the Data Collector API, see [Migrate from Data Collector API and custom fields-enabled tables to DCR-based custom logs](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/custom-logs-migrate).

## Supported tables

### Custom tables
The Logs Ingestion API can send data to any custom table that you create and to certain Azure tables in your Log Analytics workspace. The target table must exist before you can send data to it. Custom tables must have the _CL suffix.

### Azure tables
The Logs Ingestion API can send data to the following Azure tables. Other tables may be added to this list as support for them is implemented.

* CommonSecurityLog
* SecurityEvents
* Syslog
* WindowsEvents

#### Naming conventions
Column names must start with a letter and can consist of up to 45 alphanumeric characters and the characters _ and -. 

The following are reserved column names: Type, TenantId, resource, resourceid, resourcename, resourcetype, subscriptionid, tenanted. 

Custom columns you add to an Azure table must have the suffix _CF.

### Authentication
Authentication for the Logs Ingestion API is performed at the DCE, which uses standard Azure Resource Manager authentication. 

A common strategy is to use an application ID and application secret.

### Data collection rule
Data collection rules define data collected by Azure Monitor and specify how and where that data should be sent or stored. The REST API call must specify a DCR to use. A single DCE can support multiple DCRs, so you can specify a different DCR for different sources and target tables.

The DCR must understand the structure of the input data and the structure of the target table. If the two don't match, it can use a transformation to convert the source data to match the target table. You can also use the transformation to filter source data and perform any other calculations or conversions.

### Send data
To send data to Azure Monitor with the Logs Ingestion API, make a POST call to the DCE over HTTP.


#### Endpoint URI
The endpoint URI uses the following format, where the Data Collection Endpoint and DCR Immutable ID identify the DCE and DCR. 

Stream Name refers to the stream in the DCR that should handle the custom data.

```
{Data Collection Endpoint URI}/dataCollectionRules/{DCR Immutable ID}/streams/{Stream Name}?api-version=2021-11-01-preview
```

### Headers
|Header | Required | Value | Description|
|:------|:------   |:------|:------     |
|Authorization|Yes|Bearer (bearer token obtained through the client credentials flow)||
|Content-Type|Yes|application/json||
Content-Encoding|No|gzip|Use the gzip compression scheme for performance optimization.|
|x-ms-client-request-id|No|String-formatted GUID|Request ID that can be used by Microsoft for any troubleshooting purposes.|

### Body
The body of the call includes the custom data to be sent to Azure Monitor. 

The shape of the data must be a JSON object or array with a structure that matches the format expected by the stream in the DCR. 

Additionally, it is important to ensure that the request body is properly encoded in UTF-8 to prevent any issues with data transmission.

### Sample call
For sample data and an API call using the Logs Ingestion API

## Tutorials
[Send data to Azure Monitor Logs by using a REST API (Azure portal)](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal)

[Send data to Azure Monitor Logs using REST API (Resource Manager templates)](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-api)



<details>
  <summary>Get-AzAccessTokenManagement</summary>

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

</details>

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
