function Get-SfBClientEvent {
    <#
            .Synopsis
            Helper function to get Skype for Business UCWA Events

            .Description
            This function queries the Skype for Business UCWA for new events. The timeout is passed to get an empty result with just a next link when there is no information from Skype for Business. 
            In the Skype for Business Client module, this function runs in a seperate runspace in the background to query incoming events.

    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        # The timeout before the UCWA API sends an empty event, the minimum value is 180 seconds
        [Parameter()]
        [ValidateRange(180,1800)]
        [int]$TimeOut,
    
        # Skype for Business Client module context
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }

    # Return the results from the event and store the next event in the context.
    
    $eventUri = '{0}{1}' -f $Context.rootUri, $Context.events['next']
    $null = $eventUri -match '(?<eventId>[0-9]*$)' 
    [int]$eventId = $matches.eventId
    
    If($TimeOut) {
        $eventUri = '{0}{1}' -f $eventUri, "&timeout=$TimeOut"
    }
    
    Try {
        $event = Invoke-RestMethod -Method Get -Uri $eventUri @rest -ErrorAction stop
    
        $Context.events['next'] = $event._links.next.href
    
        # Store this event in the global context
        $Context.events[$eventId] = $event
    
        Write-Output $event
    }
    Catch {
        Write-Error $_
    }
}