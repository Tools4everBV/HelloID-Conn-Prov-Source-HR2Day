#####################################################
# HelloID-Conn-Prov-Source-HR2Day-Persons
#
# Version: 1.0.0.1
#####################################################
$VerbosePreference = "Continue"

#Region Functions
function Get-HR2DayEmployeeData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]
        $ClientID,

        [Parameter(Mandatory)]
        [string]
        $ClientSecret,

        [Parameter(Mandatory)]
        [string]
        $UserName,

        [Parameter(Mandatory)]
        [string]
        $Password,

        [Parameter(Mandatory)]
        [string]
        $WG_Employees,

        [bool]
        $IsConnectionTls12
    )

    try {
        if ($IsConnectionTls12) {
            Write-Verbose 'Switching to TLS 1.2'
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
        }

        Write-Verbose "Invoking command '$($MyInvocation.MyCommand)'"
        Write-Verbose 'Retrieving HR2Day AccessToken'
        $form = @{
            grant_type    = 'password'
            username      = $UserName
            client_id     = $ClientID
            client_secret = $clientSecret
            password      = $Password
        }
        $accessToken = Invoke-RestMethod -Uri $Uri -Method Post -Form $form

        Write-Verbose 'Adding Authorization headers'
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", "Bearer $($accessToken.access_token)")
        $splatParams = @{
            Headers = $headers
        }

        Write-Verbose 'Retrieving HR2Day Employees'
        $splatParams['Endpoint']="employee?wg=$WG_Employees"
        $employeeData = Invoke-HR2DayRestMethod @splatParams

        Write-Verbose 'Retrieving HR2Day Arbeidsrelaties'
        $splatParams['Endpoint']="arbeidsrelatie?wg=$WG_Employees"
        $arbeidsRelatieData = Invoke-HR2DayRestMethod @splatParams

        Write-Verbose 'Combining Employee and Arbeidsrelaties data'

        # Lookup table using a delegate
        $contractDelegate = [Func[object, object]] { param($contract) $contract.hr2d__Employee__c }
        $lookup = [Linq.Enumerable]::ToLookup($arbeidsRelatieData, $contractDelegate)

        # Lookup table using native PS Group-Object
        # $lookup = $arbeidsRelatieData | Group-Object -Property hr2d__Employee__c -AsHashTable

        foreach ($employee in $employeeData){

            # Lookup the contracts for the employee using Linq
            $arbeidsRelaties = [Linq.Enumerable]::ToArray($lookup[$employee.Id])

            # Lookup the contracts for the employee using native PS
            # $arbeidsRelaties = $lookup[$employee.Id]

            $arbeidsRelaties.Foreach(
            {
                $_ | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $_.Id
            })

            $employee | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $employee.hr2d__EmplNr__c
            $employee | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $employee.hr2d__A_name__c
            $employee | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value $arbeidsRelaties
        }

        Write-Output $employeeData | ConvertTo-Json -Depth 20
    } catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -Error $ex
            Write-Verbose "Could not retrieve HR2Day employees. Error: $errorMessage"
        } else {
            Write-Verbose "Could not retrieve HR2Day employees. Error: $($ex.Exception.Message)"
        }
    }
}
#Endregion Functions

#Region Helper Functions
function Invoke-HR2DayRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Endpoint,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]
        $Headers
    )

    process {
        try {
            Write-Verbose "Invoking command '$($MyInvocation.MyCommand)' to endpoint '$Endpoint'"
            $splatRestMethodParameters = @{
                Uri         = "https://eu1.salesforce.com/services/apexrest/hr2d/$Endpoint"
                Method      = 'Get'
                ContentType = 'application/json'
                Headers     = $Headers
            }
            Invoke-RestMethod @splatRestMethodParameters
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

function Resolve-HTTPError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory,
            ValueFromPipeline
        )]
        [object]$ErrorObject
    )

    process {
        $HttpErrorObj = @{
            FullyQualifiedErrorId = $ErrorObject.FullyQualifiedErrorId
            MyCommand             = $ErrorObject.InvocationInfo.MyCommand
            RequestUri            = $ErrorObject.TargetObject.RequestUri
        }
        if ($ErrorObject.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') {
            $HttpErrorObj['ErrorMessage'] = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            $stream = $ErrorObject.Exception.Response.GetResponseStream()
            $stream.Position = 0
            $streamReader = New-Object System.IO.StreamReader $Stream
            $errorResponse = $StreamReader.ReadToEnd()
            $HttpErrorObj['ErrorMessage'] = $errorResponse
        }
        Write-Output "'$($HttpErrorObj.ErrorMessage)', TargetObject: '$($HttpErrorObj.RequestUri), InvocationCommand: '$($HttpErrorObj.MyCommand)"
    }
}
#Endregion Helper Functions

$connectionSettings = $Configuration | ConvertFrom-Json
$splatParams = @{
    ClientID          = $($connectionSettings.ClientID)
    ClientSecret      = $($connectionSettings.ClientSecret)
    Username          = $($connectionSettings.UserName)
    Password          = $($connectionSettings.Password)
    WG_Employees      = $($connectionSettings.WG_Employees)
    IsConnectionTls12 = $($connectionSettings.IsConnectionTls12)
}
Get-HR2DayEmployeeData @splatParams
