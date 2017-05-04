$TimeOut = 180

$rest = @{
    ContentType = 'application/json'
    Headers = $SkypeForBusinessClientModuleContext.authHeader
}

# Return the results from the event and store the next event in the SkypeForBusinessClientModuleContext.
    
$eventUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri, $SkypeForBusinessClientModuleContext.events['next']
$null = $eventUri -match '(?<eventId>[0-9]*$)' 
[int]$eventId = $matches.eventId
    
If($TimeOut) {
    $eventUri = '{0}{1}' -f $eventUri, "&timeout=$TimeOut"
}
    
Try {
    $event = Invoke-RestMethod -Method Get -Uri $eventUri @rest -ErrorAction stop
    
    $SkypeForBusinessClientModuleContext.events['next'] = $event._links.next.href
    
    # Store this event in the global SkypeForBusinessClientModuleContext
    $SkypeForBusinessClientModuleContext.events[$eventId] = $event
    
    Write-Output $event
}
Catch {
    Write-Error $_
}