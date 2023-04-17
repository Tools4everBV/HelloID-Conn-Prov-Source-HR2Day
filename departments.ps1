#####################################################
# HelloID-Conn-Prov-Source-HR2Day-Departments
#
# Version: 1.0.1
#####################################################
$VerbosePreference = "Continue"

#Region Functions
function Get-HR2DayDepartmentData {
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
        $WG_Departments,

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
        $accessToken = Invoke-RestMethod -Uri 'https://login.salesforce.com/services/oauth2/token' -Method Post -Form $form

        Write-Verbose 'Adding Authorization headers'
        $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $headers.Add("Authorization", "Bearer $($accessToken.access_token)")
        $splatParams = @{
            Headers = $headers
        }

        $splatParams['InstanceUrl'] = "$($accessToken.instance_url)"

        Write-Verbose 'Retrieving HR2Day Departments'
        $splatParams['Endpoint'] = "department?wg=$WG_Departments"
        $departmentData = Invoke-HR2DayRestMethod @splatParams

        foreach ($record in $departmentData) {  
            $department = [PSCustomObject]@{
                ExternalId        = $record.Id
                ShortName         = $record.Name
                DisplayName       = $record.hr2d__Description__c
                ManagerExternalId = $record.hr2d__Manager__c
                ParentExternalId  = $record.hr2d__ParentDept__c
            }
            
            # Sanitize and export the json
            $department = $department | ConvertTo-Json -Depth 10
            $department = $department.Replace("._", "__")
            
            Write-Output $department
        }


        Write-Verbose 'Importing raw data in HelloID'
        if (-not ($dryRun -eq $true)) {
            Write-Verbose "[Full import] importing '$($departmentData.count)' departments"
            Write-Output $departmentData | ConvertTo-Json -Depth 10
        }
        else {
            Write-Verbose "[Preview] importing '$($departmentData[1..10].count)' departments"
            Write-Output $departmentData[1..10] | ConvertTo-Json -Depth 10
        }
    }
    catch {
        $ex = $PSItem
        if ( $($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
            $errorMessage = Resolve-HTTPError -Error $ex
            Write-Verbose "Could not retrieve HR2Day employees. Error: $errorMessage"
        }
        else {
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
        [ValidateNotNullOrEmpty()]
        [string]
        $InstanceUrl,

        [Parameter(Mandatory)]
        [System.Collections.IDictionary]
        $Headers
    )

    process {
        try {
            Write-Verbose "Invoking command '$($MyInvocation.MyCommand)' to endpoint '$Endpoint' on url '$InstanceUrl'"
            $splatRestMethodParameters = @{
                Uri         = "$InstanceUrl/services/apexrest/hr2d/$Endpoint"
                Method      = 'Get'
                ContentType = 'application/json'
                Headers     = $Headers
            }
            Invoke-RestMethod @splatRestMethodParameters
        }
        catch {
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
        }
        elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
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
    WG_Departments    = $($connectionSettings.WG_Departments)
    IsConnectionTls12 = $($connectionSettings.IsConnectionTls12)
}
Get-HR2DayDepartmentData @splatParams