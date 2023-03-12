# Introduction
I am realy happy to announce my Powershell module, **AzLogDcrIngestPS**

This module can ease if you want to send any data to **Azure LogAnalytics custom logs** - using the cool features of **Azure Log Ingestion Pipeline**, **Azure Data Colection Rules & Log Ingestion API**. It supports creation/update of DCRs and tables including schema, management of transformations, handles schema changes, includes lots of great data filtering capabilities.

Core features of Powershell module **AzLogDcrIngestPS**:
* create/update the DCRs and tables automatically - based on the source object schema
* validate the schema for naming convention issues. If exist found, it will mitigate the issues
* update schema of DCRs and tables, if the structure of the source object changes
* auto-fix if something goes wrong with a DCR or table
* can remove data from the source object, if there are colums of data you don't want to send
* can convert source objects based on CIM or PS objects into PSCustomObjects/array
* can add relevant information to each record like UserLoggedOn, Computer, CollectionTime

I have built a showcase - [ClientInspector (v2)](https://github.com/KnudsenMorten/ClientInspectorV2), where you can see how you can use the Powershell module, **AzLogDcrIngestPS**. 

[ClientInspector](https://github.com/KnudsenMorten/ClientInspectorV2) is free to the community - built to be a cool showcase of how you can bring back data from your clients using **Azure Log Ingestion Pipeline**, **Azure Data Collection Rules**, **Azure LogAnalytics**; view them with **Azure Monitor & Azure Dashboards** - and get "drift-alerts" using **Microsoft Sentinel**.

You can download latest version here or Powershell Gallery:

[AzLogDcringestPS (Github)](https://github.com/KnudsenMorten/AzLogDcrIngestPS)

[AzLogDcringestPS (Powershell Gallery)](https://www.powershellgallery.com/packages/AzLogDcrIngestPS)

<br>

[Big Thanks to the great people in Azure LogAnaytics/DCR/AMA/VMInsight/Workbooks product teams - you deliver rock stars solution :smile:](#big-thanks-to-the-great-people-in-azure-loganayticsdcramavminsightworkbooks-product-teams---you-deliver-rock-stars-solution-smile)


<details>
  <summary><h2>Background for building this Powershell module</h2></summary>
  
For the last 5 years, I have been using the Log Analytics Data Collector API - also referred to 'Azure Monitor HTTP Data Collector API' - or my short name for it "MMA-method"



> Don't let yourself be confused, when you are searching the internet for 'Azure Monitor HTTP Data Collector' and it comes up saying it is in **public preview**. It is <ins>still the legacy API</ins> which will be **replaced** by Log Ingestion API and DCRs.

> Product team quotes: “Data Collector API was never officially released or considered "complete”. We are going to update Data Collector API documentation as part of its deprecation cycle”

I have using the API with my Powershell scripts to upload 'tons' of custom data into Azure LogAnalytics. On top, I provided 35 Azure dashboards, that gives me (and my customers) great insight to the health and security of their environment.

![Flow-MMA](img/Concept-legacy-mma.png)

Moving forward, Microsoft has introduced the concept of **Azure Data Collection Rules (DCRs)**, which I am a big fan of.

The reasons for that are:
* support for file based logs collection (txt, Windows Firewall)
* advanced support for collection of performance data (fx. SQL performance performance counters)
* support for SNMP traps logs collection
* possibiity to remove data before being sent into LogAnalytics (remove "noice" data/cost optimization, GDPR/compliance)
* possibility to add data before being sent into LogAnalytics (normalization)
* possibility to merge data before being sent into LogAnalytics (normalization)
* security is based on Azure AD RBAC
* naming of data columns are prettier, as they contain the actual name - and not for example ComputerName_s indicating it is a string value
* data quality is better for array data, as array data is converted into dynamic - whereas the old MMA-method would convert array data into strings
* future: support to send to other destinations (AMA only)

If I should mention some disadvantages, then they are:
* complexity is higher, because you have 1-2 more "middle-tiers" involved (DCR, DCE)
* table/DCR/schema must be defined before sending data (this is why I build the powershell function AzLogDcrIngestPS)

The overall goals for **AzLogDcrIngestPS** are to **automate** all the steps - and **ensure data schema alignment to requirement**.

If you are interested in learning more about Azure Data Collection Rules and the different options, I urge you to read the section

</details>

## Source data - what data can I use ?
You can use **any source data** which can be retrieved by Powershell into an object (wmi, cim, external data, rest api, xml-format, json-format, csv-format, etc.)

ClientInspector uses several functions within the Powershell module, **AzLogDcIngestPS**, to handle source data adjustsments to **remove "noice" in data**, to **remove prohibited colums in tables/DCR** - and support needs for **transparency** with extra insight like **UserLoggedOn**, **CollectionTime**, **Computer**:


## Detailed information about AzLogDcrIngestPS functions

<details>
  <summary>Sample usage of functions Convert-CimArrayToObjectFixStructure, Add-CollectionTimeToAllEntriesInArray, Add-ColumnDataToAllEntriesInArray, ValidateFix-AzLogAnalyticsTableSchemaColumnNames, Build-DataArrayToAlignWithSchema, Filter-ObjectExcludeProperty</summary>

ClientInspector uses several functions within the Powershell module, **AzLogDcIngestPS**, to handle source data adjustsments to **remove "noice" in data**, to **remove prohibited colums in tables/DCR** - and support needs for **transparency** with extra insight like **UserLoggedOn**, **CollectionTime**, **Computer**:

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


<details>
  <summary><h4>Get-AzAccessTokenManagement</h4></summary>

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

<details>
  <summary><h3>CreateUpdate-AzLogAnalyticsCustomLogTableDcr</h3></summary>

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
</details>

<details>
  <summary><h2>CreateUpdate-AzDataCollectionRuleLogIngestCustomLog</h2></summary>
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
</details>

<details>
  <summary><h2>Update-AzDataCollectionRuleResetTransformKqlDefault</h2></summary>
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
</details>

<details>
  <summary><h2>Update-AzDataCollectionRuleTransformKql</h2></summary>
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
</details>

<details>
  <summary><h2>Update-AzDataCollectionRuleLogAnalyticsCustomLogTableSchema</h2></summary>
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
</details>

<details>
  <summary><h2>Update-AzDataCollectionRuleDceEndpoint</h2></summary>
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
</details>

<details>
  <summary><h2>Delete-AzLogAnalyticsCustomLogTables</h2></summary>
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
</details>

<details>
  <summary><h2>Delete-AzDataCollectionRules</h2></summary>
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
</details>

<details>
  <summary><h2>Get-AzDcrDceDetails</h2></summary>
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
</details>

<details>
  <summary><h2>Post-AzLogAnalyticsLogIngestCustomLogDcrDce</h2></summary>
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
</details>

<details>
  <summary><h2>ValidateFix-AzLogAnalyticsTableSchemaColumnNames</h2></summary>
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
</details>

<details>
  <summary><h2>Build-DataArrayToAlignWithSchema</h2></summary>
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
</details>

<details>
  <summary><h2>Get-AzLogAnalyticsTableAzDataCollectionRuleStatus</h2></summary>

Get-AzLogAnalyticsTableAzDataCollectionRuleStatus

</details>
 
<details>
  <summary><h2>Add-ColumnDataToAllEntriesInArray</h2></summary>
Add-ColumnDataToAllEntriesInArray
</details>
 
<details>
  <summary><h2>Add-CollectionTimeToAllEntriesInArray</h2></summary>
Add-CollectionTimeToAllEntriesInArray
</details>
 
<details>
  <summary><h2>Convert-CimArrayToObjectFixStructure</h2></summary>
Convert-CimArrayToObjectFixStructure
</details>
 
<details>
  <summary><h2>Convert-PSArrayToObjectFixStructure</h2></summary>
Convert-PSArrayToObjectFixStructure
</details>
 
<details>
  <summary><h2>Get-ObjectSchemaAsArray</h2></summary>
Get-ObjectSchemaAsArray
</details>
 
<details>
  <summary><h2>Get-ObjectSchemaAsHash</h2></summary>
Get-ObjectSchemaAsHash
</details>
 
<details>
  <summary><h2>Filter-ObjectExcludeProperty</h2></summary>

Filter-ObjectExcludeProperty

</details>
 
<details>
  <summary><h2>Get-AzDcrListAll</h2></summary>

Get-AzDcrListAll

</details>
 
<details>
  <summary><h2>Get-AzDceListAll</h2></summary>
Get-AzDceListAll
</details>
 
<details>
  <summary><h2>Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output</h2></summary>
Post-AzLogAnalyticsLogIngestCustomLogDcrDce-Output
</details>
 
<details>
  <summary><h2>CheckCreateUpdate-TableDcr-Structure</h2></summary>
CheckCreateUpdate-TableDcr-Structure
</details>

<br>

<details>
  <summary><h1>Deep-dive about Azure Data Collection Rules (DCRs)</h1></summary>

## Understanding Data Collection Rules - step 1: Data-In (source data)
As shown on the picture, a core change is the new middletier, **Azure Data Collection ingestion pipeline** - or in short '**DCR-pipeline**'

<br>

![Flow-DCR](img/Concept-dcr-pipeline.png)

<br>

Microsoft supports data from the following **sources (data-in)**:

|Collection source|Technologies required|Flow|
|:----------------|:--------------------|:---|
|(legacy)<br>Performance<br>Eventlog<br>Syslog|MMA (legacy)|1. MMA<br>2. Azure LogAnalytics|
|(legacy)<br>API|HTTP Data Collection API (legacy)|1. REST API endpoint<br>2. Azure LogAnalytics|
|Performance<br>Eventlog<br>Syslog|AMA<br>DCR<br>|1. AMA<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics|
|Text log<br>IIS logs<br>Windows Firewall logs (preview)|AMA<br>DCR<br>DCE<br>|1. AMA<br>2. DCE<br>3. DCR ingestion pipeline<br>4. Azure LogAnalytics|
|SNMP traps|Linux with SNMP trap receiver<br>AMA<br>DCR (syslog file)<br><br>-or-<br>A<br>AMA<br>DCR (syslog stream)|1. AMA<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics|
|Change Tracking (legacy)|Change Tracking Extension (FIM)<br>DCR<br>|1. FIM<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics|
|REST Log Ingestion API|REST endpoint<br>DCR<br>DCE<br>|1. REST endpoint<br>2. DCE<br>3. DCR ingestion pipeline<br>4. Azure LogAnalytics|
|Platform Metrics/Telemetry (standard) Azure PaaS|DCR (build-in, non-manageable)<br>|1. Azure Resource<br>2. DCR ingestion pipeline<br>3. Azure Monitor Metrics|
|Custom Metrics/Telemetry (custom app)|Windows (1):<br>AMA<br>DCR<br><br>-or-<br><br>Windows (2):<br>Azure Diagnostics extension<br><br>-or-<br><br>API:<br>Azure Monitor REST API<br><br>-or-<br><br>Linux: Linux InfluxData Telegraf agent (Linux)<br>Azure Monitor output plugin|Windows (1):<br>1. AMA<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics<br><br>Windows (2):<br>1. Azure Diagnostics<br>2. Azure LogAnalytics<br><br>API:<br>1. REST endpoint<br>2. DCE<br>3. DCR ingestion pipeline<br>4. Azure LogAnalytics<br><br>Linux:<br>1. Linux InfluxData<br>2. Azure Monitor output plugin<br>3. Azure LogAnalytics|
|Platform logs (diagnostics per resource)<br>AllMetrics<br>Resource logs (allLogs, audit)|Azure Policy (diagnostics)<br>DCR<br>|1. Azure Resource<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics|
|Activity logs (audit per subscription)|Azure Policy (diagnostics)<br>DCR<br>|1. Azure Resource<br>2. DCR ingestion pipeline<br>3. Azure LogAnalytics|

<br>

## Understanding Data Collection Rules - step 2: Data-Transformation
Currently, Microsoft supports doing transformation using 3 methods:

|Collection source|Transformation (where) |How|Purpose / limitatations |
|:----------------|:----------------------|:--|:-----------------------|
(legacy)<br>Performance<br>Eventlog<br>Syslog|DCR-pipeline|Workspace transformation DCR|Only one transformation per table
All sources sending in using AMA|DCR-pipeline|AMA transformation DCR|All DCRs do unions, so be aware of double data. Governance is important
|REST API using Log ingestion API|DCR-pipeline|Log Ingestion transformation DCR|

<br>

### Transformation with Azure Monitor Agent (AMA) & Azure Data Collection Rules (DCR)
![Transformation](img/Concept-transformation-ama.png)

<br>

### Transformation with Azure DCR-pipeline (Log Ingestion API) & Azure Data Collection Rule (DCR)
![Transformation](img/Concept-transformation-log-ingest.png)

<br>

### Transformation with Azure LogAnalytics Workspace Data Collection Rule (DCR)
![Transformation](img/Concept-transformation-workspace.png)

<br>

### Why is data transformation important ?
As shown below, you can do great things with the concept of **data transformation**:

|Category | Details |
|:--------|:--------|
| Remove sensitive data|You may have a data source that sends information you don’t want stored for privacy or compliancy reasons<br/><br/>**Filter sensitive information**. Filter out entire rows or just particular columns that contain sensitive information<br/><br/>**Obfuscate sensitive information**. For example, you might replace digits with a common character in an IP address or telephone number.|
|Enrich data with additional or calculated information|Use a transformation to add information to data that provides business context or simplifies querying the data later.<br/><br/>**Add a column with additional information**. For example, you might add a column identifying whether an IP address in another column is internal or external.<br/><br/>**Add business specific information**. For example, you might add a column indicating a company division based on location information in other columns.|
|Reduce data costs|Since you’re charged ingestion cost for any data sent to a Log Analytics workspace, you want to filter out any data that you don’t require to reduce your costs.<br/><br/>**Remove entire rows**. For example, you might have a diagnostic setting to collect resource logs from a particular resource but not require all of the log entries that it generates. Create a transformation that filters out records that match a certain criteria.<br/><br/>**Remove a column from each row**. For example, your data may include columns with data that’s redundant or has minimal value. Create a transformation that filters out columns that aren’t required.<br/><br/>**Parse important data from a column**. You may have a table with valuable data buried in a particular column. Use a transformation to parse the valuable data into a new column and remove the original.<br/><br/>Examples of where data-transformation is useful:<br/><br/>We want to remove specific security-events from a server, which are making lots of ”noise” in our logs due to a misconfiguration or error and it is impossible to fix it.<br/><br/>We want to remove security events, which we might show with a high amount, but we want to filter it out like kerberos computer-logon traffic.|

<br>

### Examples of transformations, based on Kusto syntax
Start by testing the query in Azure LogAnalytics. When the query is working, you will change the tablename to **source** - as shown below

| Kusto Query|Purpose|Transformation syntax for DCR 'transformKql' command|
|:-----------|:------|:---------------------------------------------------|
|SecurityEvent \| where (EventID != 12345)|Remove events with EventID 12345 in SecurityEvent table|source \| where (EventID != 12345)|
|SecurityEvent \| where (EventID != 8002) and (EventID != 5058) and (EventID != 4662)|Remove events with EventId 4662,5058,8002 in SecurityEvent table|source \| where (EventID != 8002) and (EventID != 5058) and (EventID != 4662)|
|Event \| where ( (EventID != 10016 and EventLog == “Application”)  )|Remove events with EventID 10016, if source is Application log|source \| where ( (EventID != 10016 and EventLog == “Application”)  )|
|Inventory_CL \| extend TimeGenerated = now()|Add new column TimeGenerated with the actual time (now), when data is coming in|source \| extend TimeGenerated = now()|

Intersted in learning more - check out this topic on my blog - [How to do data transformation with Azure LogAnalytics – to enrich information, optimize cost, remove sensitive data?](https://mortenknudsen.net/?p=73)

## Understanding Data Collection Rules - step 3 Data-Out (destinations)
The concept of Data Collection Rules also includes the ability to send the data to multiple destinations.

Currently, DCRs support the following destinations:

|Collection source|Technologies required|Supported Targets|
|:----------------|:--------------------|:----------------|
|Performance<br>Eventlog<br>Syslog|AMA<br>DCR|Azure LogAnalytics standard table|
|Text log<br>IIS logs<br>Windows Firewall logs (preview)|AMA<br>DCR<br>DCE|Azure LogAnalytics custom log table|
|SNMP traps|Linux with SNMP trap receiver<br>AMA<br>DCR (syslog file)<br><br>-or-<br>A<br>AMA<br>DCR (syslog stream)|Azure LogAnalytics custom log table|
|Change Tracking (legacy)|Change Tracking Extension (FIM)<br>DCR|Azure LogAnalytics standard table|
|REST Log Ingestion API|REST endpoint<br>DCR<br>DCE<br>|Azure LogAnalytics standard table (CommonSecurityLog, SecurityEvents, Syslog, WindowsEvents)<br>Azure LogAnalytics custom table|
|Platform Metrics/Telemetry (standard) Azure PaaS|DCR (build-in, non-manageable)|Azure Monitor Metrics|
|Custom Metrics/Telemetry (custom app)|Windows (1):<br>AMA<br>DCR<br><br>-or-<br><br>Windows (2):<br>Azure Diagnostics extension<br><br>-or-<br><br>API:<br>Azure Monitor REST API<br><br>-or-<br><br>Linux: Linux InfluxData Telegraf agent (Linux)<br>Azure Monitor output plugin|Azure Monitor Metrics|
|Platform logs (diagnostics per resource)<br>AllMetrics<br>Resource logs (allLogs, audit)|Azure Policy (diagnostics)<br>DCR<br>|Azure LogAnalytics standard table|
|Activity logs (audit per subscription)|Azure Policy (diagnostics)<br>DCR|Azure LogAnalytics standard table|

You should expect to see more 'destinations' in the future, DCRs can send data to. 
I am really excited about the future :smile:
</details>

<details>
  <summary><h1>Azure Log Ingestion Pipeline & Log Ingestion API</h1></summary>

The following section of information comes from [Microsoft Learn](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/logs-ingestion-api-overview)

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

</details>


<br>

# Big Thanks to the great people in Azure LogAnaytics/DCR/AMA/VMInsight/Workbooks product teams - you deliver rock stars solution :smile:
Lastly, I would like to give **big credits** to a few people, who I have worked together with on building **AzLogDcrIngestPS Powershell module** and **my daily work with the Azure log & viewing capabilities**:

|Name|Role|
|:---|:---|
|Ivan Varnitski|Program Manager - Azure Pipeline|
|Evgeny Ternovsky|Program Manager - Azure Pipeline|
|Nick Kiest|Program Manager - Azure Data Collection Rules|
|Oren Salzberg|Program Manager - Azure LogAnalytics|
|Guy Wild|Technical Writer - Azure LogAnalytics|
|John Gardner|Program Manager - Azure Workbooks|
|Shikha Jain|Program Manager - Azure Workbooks|
|Shayoni Seth|Program Manager - Azure Monitor Agent|
|Jeff Wolford|Program Manager - Azure Monitor Agent|
|Xema Pathak|Program Manager - Azure VMInsight (integration to Azure Monitor Agent)|


**Ivan & Evgeny from Azure Pipeline**
![AzurePipeline](img/AzurePipeline.jpg)


**Program Managers from Azure LogAnalytics**
![AzurePipeline](img/LogAnalytics.jpg)


**Nick, Shayoni & Xema from Azure Data Collection Rules, Azure Monitor Agent and Azure VMInsight**
![AzurePipeline](img/AzureDCR_AMA.jpg)


**John & Shikha from Azure Workbooks**
![AzurePipeline](img/AzureWorkbooks.jpg)


# Contact
If you have comments to the solution - or just want to connect with me, here are my details - would love to connect:

[Github](https://github.com/KnudsenMorten)

[Twitter](https://twitter.com/knudsenmortendk)

[Blog](https://mortenknudsen.net/)

[LinkedIn](https://www.linkedin.com/in/mortenwaltorpknudsen/)

[Microsoft MVP profile](https://mvp.microsoft.com/en-us/PublicProfile/5005156?fullName=Morten%20Knudsen)

[Sessionize](https://sessionize.com/mortenknudsen/)

[Mail](mailto:mok@mortenknudsen.net)

