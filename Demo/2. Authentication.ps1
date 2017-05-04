$Credential = $scred

$ticketUri = "$rootUri/WebTicket/oauthtoken" 
$authBody = @{
    grant_type = 'urn:microsoft.rtc:windows'
}

Try {
    $userAuth = Invoke-RestMethod -Uri $ticketUri -Body $authBody -Method Post -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -Credential $Credential -ErrorAction Stop
}
Catch {
    Throw "Authentication failed: $_"
}
$token = $userAuth

$authHeader = @{
    Authorization = "$($token.token_type) $($token.access_token)"
}

$authHeader