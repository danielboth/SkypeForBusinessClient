Try {
    $userResponse = Invoke-RestMethod -Uri $discovery._links.user.href -Headers $authHeader -ContentType $json -ErrorAction Stop
    $appUri = '{0}{1}' -f $rootUri,([System.Uri]$userResponse._links.applications.href).PathAndQuery
    $appGuid = "17ed5d75-40ce-400d-acdf-5a7f6f26af3b-$($env:USERNAME)"
    $appBody = ConvertTo-Json @{
        UserAgent = 'SkypeUcwa/PowerShell'
        EndpointId = $appGuid
        Culture = 'en-US'
    }
}
Catch {
    Throw "Failed to get Skype for Business application link. Error: $_"
}

Try {
    $application = Invoke-RestMethod -Uri $appUri -Headers $authHeader -Method Post -Body $appBody -ContentType $json -ErrorAction Stop
}
Catch {
    Throw "Failed to create Skype for Business application. Error: $_"
}

$application

$application._embedded | Format-List

$application._embedded.me | Format-List

$application._embedded.people._links | Format-List

$application._embedded.communication | Format-List