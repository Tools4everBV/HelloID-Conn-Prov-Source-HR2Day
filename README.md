# HelloID-Conn-Prov-Source-HR2Day

| :information_source: Information |
|:---------------------------|
| This repository contains the connector and configuration code only. The implementer is responsible to acquire the connection details such as clientid, clientsecret, BaseUrl etc. You might even need to sign a contract or agreement with the supplier before implementing this connector. Please contact the client's application manager to coordinate the connector requirements.       |

<br />

<p align="center">
  <img src="https://www.hr2day.com/wp-content/uploads/2019/10/cropped-RGB_hr2day_logo.png">
</p>

## Table of contents

- [HelloID-Conn-Prov-Source-HR2Day](#helloid-conn-prov-source-hr2day)
  - [Table of contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Getting started](#getting-started)
    - [Connection settings](#connection-settings)
    - [Prerequisites](#prerequisites)
      - [TLS1.2](#tls12)
      - [Pagination](#pagination)
    - [Contents](#contents)
  - [Setup the connector](#setup-the-connector)
  - [Getting help](#getting-help)
  - [HelloID docs](#helloid-docs)

## Introduction

HR2Day is an HR System and provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints in the table below.

| Endpoint | Description |
| ------------ | ----------- |
| /Emloyee | Contains the employee information. |
| /Arbeidsrelatie | Contains the information about employments. Employees can have multiple 'arbeidsrelaties'. |
| /Department | Contains the information about departments and managers. |

## Getting started

The _HelloID-Conn-Prov-Source-HR2Day_ connector is created for both Windows PowerShell 5.1 and PowerShell Core. This means that the connector can be executed in both cloud and on-premises using the HelloID agent.

### Connection settings

The following settings are required to connect to the API.

| Setting     | Description | Mandatory |
| ------------ | ----------- | ----------- |
| ClientID | The consumer clientid. This will be provided by HR2Day | Yes |
| ClientSecret | The consumer clientsecret. This will be provided by HR2Day | Yes |
| BaseUrl | The URL to connect to the API | Yes |
| WG_Employees | The name of the 'werkgever' or 'employer' for the employees in HR2Day | Yes |
| WG_Deparments | The name of the 'werkgever' or 'employer' for the departments in HR2Day | Yes |
| Enable TLS1.2 | Enables TLS 1.2 | No |
| YearRange | The range of years in single digits e.g. 5, that determines the range for which the contract/workRelations [arbeidsrelaties] are retuned | No |

> The _YearRange_ is used to decrease the dataset send back from HR2Day. Use this setting when the connector displays the error __'Could not retrieve arbeidsrelatiedata, the result exceeds the limit'__

### Prerequisites

- [ ] Make sure to have gathered all necessary connection settings
- [ ] The values for __WG_Departments__ and __WG_Employees__

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

## Getting help

> [!TIP]
> _For more information on how to configure a HelloID PowerShell connector, please refer to our [documentation](https://docs.helloid.com/en/provisioning/Source-systems/powershell-v2-Source-systems.html) pages_.

## HelloID docs

The official HelloID documentation can be found at: https://docs.helloid.com/
