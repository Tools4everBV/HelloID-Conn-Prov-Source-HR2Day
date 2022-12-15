#####################################################
# HelloID-Conn-Prov-Source-HR2Day-Persons
#
# Version: 1.0.0.4
#####################################################
$VerbosePreference = "Continue"

#region functions
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
        $IsConnectionTls12,

        [string]
        $YearRange
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
        $accessToken = Invoke-RestMethod -Uri 'https://login.salesforce.com/services/oauth2/token' -Method Post -Form $form

        Write-Verbose 'Adding Authorization headers'
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", "Bearer $($accessToken.access_token)")
        $splatParams = @{ Headers = $headers }

        $splatParams['InstanceUrl'] = "$($accessToken.instance_url)"

        Write-Verbose 'Retrieving HR2Day Employees'
        $splatParams['Endpoint']="employee?wg=$WG_Employees"
        $employeeData = Invoke-HR2DayRestMethod @splatParams

        Write-Verbose 'Retrieving HR2Day Arbeidsrelaties'
        if ($YearRange) {
            [System.Collections.ArrayList]$resultArray = @()
            $yearRangeInt = $YearRange -as [int]
            $startRange = $yearRangeInt
            $endRange = $yearRangeInt
            $currentYear = Get-Date
            ############################################################################################################
            # Note: the functionallity below is merely an example to show you how paging could be done.
            #
            # Since the API does not support paging, we have to do our own paging.
            # This is achieved by retrieving the arbeidsRelatieData in small yearly batches.
            # If you provide a YearRange of 5 from the configuration, 5 consecutive API calls will be made.
            # If the current year is 2021, the first batch contains data from [20160101 - 20170101]. And so on.
            # The last call in the do/until loop contains the data from [20200101 - 20210101].
            #
            # We then have to make one additional call outside the loop to get the data from [20210101 - Now]
            # where [Now] at this moment is set to; 20211231.
            ############################################################################################################
            do {
                $endRange--
                $startDateYear = $currentYear.AddYears(-$startRange).ToString("yyyy")
                $endDateYear = $currentYear.AddYears(-$endRange).ToString("yyyy")
                $startDate = "$($startDateYear)0101"
                $endDate = "$($endDateYear)0101"
                $splatParams['Endpoint']="arbeidsrelatie?wg=$WG_Employees&dateFrom=$startDate&dateTo=$endDate"
                $arbeidsRelatieData = Invoke-HR2DayRestMethod @splatParams
                $resultArray.AddRange($arbeidsRelatieData) | Out-Null
                $startRange--
            } until ($startRange -eq -1)
                # $startDate = "$($currentYear.ToString("yyyy"))0101"
                # $endDate = (Get-Date -Month 12 -Day 31).ToString("yyyyMMdd")
                # $splatParams['Endpoint']="arbeidsrelatie?wg=$WG_Employees&dateFrom=$startDate&dateTo=$endDate"
                # $arbeidsRelatieData = Invoke-HR2DayRestMethod @splatParams
                # $resultArray.add($arbeidsRelatieData) | Out-Null
        } else {
            $splatParams['Endpoint']="arbeidsrelatie?wg=$WG_Employees"
            $arbeidsRelatieData = Invoke-HR2DayRestMethod @splatParams
        }

        if ($arbeidsRelatieData -match "JSON_PARSER_ERROR"){
            throw 'Could not retrieve arbeidsrelatiedata, the result exceeds the limit'
        } else {
            Write-Verbose 'Combining Employee and Arbeidsrelaties data'
            $contractDelegate = [Func[object, object]] {
                param ($contract) $contract.hr2d__Employee__c
            }
            $lookup = [Linq.Enumerable]::ToLookup($arbeidsRelatieData, $contractDelegate)
            #$lookup = $resultArray | Group-Object -AsHashTable -Property hr2d__Employee__c


            [System.Collections.Generic.List[object]]$resultList = @()
            foreach ($employee in $employeeData){
                $arbeidsRelaties = [Linq.Enumerable]::ToArray($lookup[$employee.Id])
                if ($arbeidsRelaties.count -ge 1){
                    $arbeidsRelaties.Foreach({
                        $_ | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $_.Id
                        $_ | Add-Member -MemberType NoteProperty -Name 'EmployerId' -Value $employee.hr2d__Employer__r.Id
                        $_ | Add-Member -MemberType NoteProperty -Name 'EmployerName' -Value $employee.hr2d__Employer__r.Name
                    })
                    $employee | Add-Member -MemberType NoteProperty -Name 'ExternalId' -Value $employee.Id
                    $employee | Add-Member -MemberType NoteProperty -Name 'DisplayName' -Value $employee.hr2d__A_name__c
                    $employee | Add-Member -MemberType NoteProperty -Name 'Contracts' -Value $arbeidsRelaties

                    $resultList.add($employee)
                }
            }
        }
        Write-Verbose 'Finised retrieving HR2Day employees. Only employees with one ore more contracts are included in the raw data'
        Write-Verbose 'Importing raw data in HelloID'
        if (-not ($dryRun -eq $true)){
            Write-Verbose "[Full import] importing '$($resultList.count)' persons"
            Write-Output $resultList | ConvertTo-Json -Depth 20
        } else {
            Write-Verbose "[Preview] importing '$($resultList[1..2].count)' persons"
            Write-Output $resultList[1..2] | ConvertTo-Json -Depth 20
        }
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
#endregion functions

#region helper functions
function Invoke-HR2DayRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Endpoint,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $InstanceUrl,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]
        $Headers
    )

    process {
        try {
            Write-Verbose "Invoking command '$($MyInvocation.MyCommand)' to endpoint '$Endpoint' to Url $InstanceUrl"
            $splatRestMethodParameters = @{
                Uri         = "$InstanceUrl/services/apexrest/hr2d/$Endpoint"
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
#endregion helper functions

$connectionSettings = $Configuration | ConvertFrom-Json
$splatParams = @{
    ClientID          = $($connectionSettings.ClientID)
    ClientSecret      = $($connectionSettings.ClientSecret)
    Username          = $($connectionSettings.UserName)
    Password          = $($connectionSettings.Password)
    WG_Employees      = $($connectionSettings.WG_Employees)
    IsConnectionTls12 = $($connectionSettings.IsConnectionTls12)
    YearRange         = $($connectionSettings.YearRange)
}
Get-HR2DayEmployeeData @splatParams