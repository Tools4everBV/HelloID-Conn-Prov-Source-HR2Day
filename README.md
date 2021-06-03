# HelloID-Conn-Prov-Source-HR2Day
### Work-In-Progress

<p align="center">
  <img src="https://www.hr2day.com/wp-content/uploads/2019/10/cropped-RGB_hr2day_logo.png">
</p>

## Table of contents

- [Introduction](#Introduction)
- [Getting started](#Getting-started)
  + [Connection settings](#Connection-settings)
  + [Prerequisites](#Prerequisites)
  + [Remarks](#Remarks)
  + [Contents](#Contents)
- [Setup the connector](Setup-The-Connector)
- [Getting help](Getting-help)
- [HelloID Documentation](HelloID-Docs)

## Introduction

HR2Day is an HR System and provides a set of REST API's that allow you to programmatically interact with it's data. The HelloID connector uses the API endpoints in the table below.

| Endpoint     | Description |
| ------------ | ----------- |
| /Emloyee     | Contains the employee information            |
| /Arbeidsrelatie    | Contains the information about employments. Employees can have multiple 'arbeidsrelaties'.            |
| /Department | * Currently not being used since the demo enviroment does not contain departments                |
| /CostCenter | * Currently not being used since the demo enviroment does not contain costcenters                |
| /Jobs | * Currently not being used since the demo enviroment does not contain jobs            |

> This connector is built on a demo environment that doesn't contain information other than employee(s) and arbeidsrelatie(s). Therefore, this connector has not been finished and the _Departments.ps1_ script hasn't been written as of yet.

## Getting started

The _HelloID-Conn-Prov-Source-HR2Day_ connector is built for both Windows PowerShell 5.1 and PowerShell Core 7. This means the connector can be executed using the _On-Premises_ HelloID agent as well as in the cloud.

### Connection settings

The following settings are required to connect to the API.

| Setting     | Description |
| ------------ | ----------- |
| ApiKey     | The consumer key. This will be provided by HR2Day          |
| ApiSecret    | The consumer secret. This will be provided by HR2Day          |
| UserName | The username to connect to the API |
| Password | The password belonging to the username |
| Werkgever | The name of the 'werkgever' or 'employer'. This the name of the employer in HR2Day |
| Beveiligingstoken | The security token. This will be provided by HR2Day |

> Optional is abbilty to toggle TLS1.2. This is only necessary when running the connector in the cloud.

### Prerequisites

- Make sure to have gathered all necessary connection settings

### Remarks

> This connector is built upon a demo environment that doesn't contain information other than employee(s) and arbeidsrelatie(s). Therefore, this connector has not been finished and the _Departments.ps1_ script hasn't been writting as of yet.

The data in HR2Day must be retrieved using multiple queries/endpoints. For an overview of endpoints, please refer to the [Introduction](#Introduction) section of this document.

### Contents

| Files       | Description                                |
| ----------- | ------------------------------------------ |
| Configuration.json | The configuration settings for the connector |
| Persons.ps1 | Retrieves the person and contract data     |

## Setup the connector

For help setting up a new source connector, please refer to our [documentation](https://docs.helloid.com/hc/en-us/articles/360012388639-How-to-add-a-source-system)

## Getting help

> _If you need help, feel free to ask questions on our [forum](https://forum.helloid.com)_

## HelloID Docs

The official HelloID documentation can be found at: https://docs.helloid.com/
