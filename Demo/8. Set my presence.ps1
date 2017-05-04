 # How presence works:
 Start-Process iexplore.exe 'C:\repositories\SkypeForBusinessClient\Demo\presence.jpg'
 
 $availability = 'Online'
 
 $rest = @{
    ContentType = 'application/json'
    Headers = $SkypeForBusinessClientModuleContext.authHeader
}
    
$makeMeAvailable = $false
$myPresenceUri = '{0}{1}{2}' -f $SkypeForBusinessClientModuleContext.rootUri, $SkypeForBusinessClientModuleContext.application._embedded.me._links.self.href, '/presence'
    
Try {
    $myPresence = Invoke-RestMethod -Method Get -Uri $myPresenceUri @rest -ErrorAction stop
}
Catch {
    If(($_.ErrorDetails.Message | ConvertFrom-Json).subcode -eq 'MakeMeAvailableRequired') {
        $makeMeAvailable = $true
    }
}
    
If($makeMeAvailable) {
    $makeMeAvailableUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri, $SkypeForBusinessClientModuleContext.application._embedded.me._links.makeMeAvailable.href
    $makeMeAvailableBody = ConvertTo-Json @{
        signInAs = $availability
        supportedMessageFormat = 'Plain'
        supportedModalities = @('Messaging')
    }

    $null = Invoke-RestMethod -Method Post -Uri $makeMeAvailableUri -Body $makeMeAvailableBody @rest -ErrorAction Stop
}
else {
    $myPresenceBody = ConvertTo-Json @{
        availability = $availability
    }
        
    $null = Invoke-RestMethod -Method Post -Uri $myPresenceUri -Body $myPresenceBody @rest
}

$reportMyActivityUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.applicationUri, '/reportMyActivity'
Invoke-RestMethod -Uri $reportMyActivityUri -Method Post -Headers $SkypeForBusinessClientModuleContext.authHeader