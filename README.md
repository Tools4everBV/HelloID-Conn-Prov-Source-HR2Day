# HelloID-Conn-Prov-Source-HR2Day

<p align="center">
  <img src="https://www.hr2day.com/wp-content/uploads/2019/10/cropped-RGB_hr2day_logo.png">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Execute the connector using the HelloID Agent](Execute-the-connector-using-the-HelloID-Agent)
  + [Remarks](#Remarks)
  + [Contents](#Contents)
- [Setup the connector](Setup-The-Connector)
- [Change history](Change-history)
- [Getting help](Getting-help)
- [HelloID Documentation](HelloID-Docs)

## Introduction

HR2Day is an HR System and provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints in the table below.

| Endpoint | Description |
| ------------ | ----------- |
| /Emloyee | Contains the employee information. |
| /Arbeidsrelatie | Contains the information about employments. Employees can have multiple 'arbeidsrelaties'. |
| /Department | Contains the information about departments and managers. |

## Getting started

The _HelloID-Conn-Prov-Source-HR2Day_ connector is created for both Windows PowerShell 5.1 and PowerShell Core. This means that the connector can be executed in both cloud and on-premises using the HelloID agent.

> If you want to execute the connector using the HelloID agent, please check section: [Execute the connector using the HelloID Agent](Execute-the-connector-using-the-HelloID-Agent)

### Connection settings

The following settings are required to connect to the API.

| Setting     | Description | Mandatory |
| ------------ | ----------- | ----------- |
| ApiKey | The consumer key. This will be provided by HR2Day | Yes |
| ApiSecret | The consumer secret. This will be provided by HR2Day | Yes |
| UserName | The username to connect to the API | Yes |
| Password | The password belonging to the username + Plus security code  | Yes |
| WG_Employees | The name of the 'werkgever' or 'employer' for the employees in HR2Day | Yes |
| WG_Deparments | The name of the 'werkgever' or 'employer' for the departments in HR2Day | Yes |
| Enable TLS1.2 | Enables TLS 1.2 | No |
| YearRange | The range of years in single digits e.g. 5, that determines the range for which the contract/workRelations [arbeidsrelaties] are retuned | No |

> The _YearRange_ is used to decrease the dataset send back from HR2Day. Use this setting when the connector displays the error __'Could not retrieve arbeidsrelatiedata, the result exceeds the limit'__

### Prerequisites

- [ ] Make sure to have gathered all necessary connection settings

- [ ] The values for __WG_Departments__ and __WG_Employees__

#### When using the connector in conjunction with the HelloID agent

- [ ] The PSHR2DayAuth module files. Download from: https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-HR2Day/tree/main/PSHR2DayAuth/bin

- [ ] Windows PowerShell 5.1 installed on the server where the 'HelloID agent and provisioning agent' are running. Download from: https://www.microsoft.com/en-us/download/details.aspx?id=54616

- [ ] .NET 4.7.2 (or higher) installed on the server where the 'HelloID agent and provisioning agent' are running. Download from: https://dotnet.microsoft.com/download/dotnet-framework/net472

- [ ] Adjust the PowerShell code for both _persons.ps1_ and _departments.ps1_. See section [Execute the connector using the HelloID Agent](Execute-the-connector-using-the-HelloID-Agent)

### Execute the connector using the HelloID Agent

1. Download all the files from the repository https://github.com/Tools4everBV/HelloID-Conn-Prov-Source-HR2Day/tree/main/PSHR2DayAuth/bin/
2. Copy the files to a sensible location.
3. Open the _persons.ps1_ and _departments.ps1_ files
4. Go to the _Get-HR(Employee/Department)Data_ function
5. Add the folowing line within the _try_ block on line 40

```powershell
Import-Module "c:\temp\PSHR2Day.dll" -Force
```
6. Make sure to adjust the path _[c:\temp\PSHR2Day.dll]_ and use the folder in which the PSHR2Day files are saved.
7. Replace the following lines:

```powershell
$form = @{
    grant_type    = 'password'
    username      = $UserName
    client_id     = $ClientID
    client_secret = $clientSecret
    password      = $Password
}
$accessToken = Invoke-RestMethod -Uri 'https://login.salesforce.com/services/oauth2/token' -Method Post -Form $form
```

Replace with:

```powershell
$splatTokenParams = @{
    UserName     = $UserName
    Password     = $Password
    ClientID     = $ClientID
    ClientSecret = $ClientSecret
}
$response = Get-HR2DayAccessToken @splatTokenParams
$accessToken = $response | ConvertFrom-Json
```

### Remarks

- When using the connector on Windows PowerShell 5.1 / The HelloID agent, you will need the PSModule DLL file to authenticate against HR2Day. Please not that the code will have to be changed in order to run on Windows PowerShell 5.1. See section [Execute the connector using the HelloID Agent](Execute-the-connector-using-the-HelloID-Agent)

#### TLS1.2

Enabling TLS 1.2 is not necessary when running the connector in the cloud

#### Pagination

Since the API does not support paging, we have to do our own paging. This is achieved by retrieving the arbeidsRelatieData in small yearly batches. If you provide a YearRange of 5 from the configuration, 5 consecutive API calls will be made. If the current year is 2021, the first batch contains data from _[20160101 - 20170101]_. And so on.

The last call in the do/until loop contains the data from _[20200101 - 20210101]_. We then have to make one additional call outside the loop to get the data from _[20210101 - Now]_ where __[Now]__ at this moment, is set to the last day of the current year.

### Contents

| Files       | Description                                |
| ----------- | ------------------------------------------ |
| Configuration.json | The configuration settings for the connector |
| Persons.ps1 | Retrieves the person and contract data |
| Departments.ps1 | Retrieves the department data |
| Mapping.json | A basic mapping for both persons and contracts |

## Setup the connector

> Make sure to configure the Primary Manager in HelloID to: __From department of primary contract__

For help setting up a new source connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012388639-How-to-add-a-source-system)

## Change history

### persons.ps1 [V1.0.0.4]

- Updated to accommodate a preview (drynRun) import

### persons.ps1 [V1.0.0.3]

- Added YearRange to decrease the dataset
- Added Errorhandling to throw when the dataset contains an error
- Added logic to include only employees with one or more contracts in the raw data 

### departments.ps1 [V1.0.0.2]

- Updated to accommodate a preview (drynRun) import


## Getting help

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID Docs

The official HelloID documentation can be found at: https://docs.helloid.com/
