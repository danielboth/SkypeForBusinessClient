Function Get-SfbClientPresence {
    <#
            .Synopsis
            Get the presence of the current user.

            .Description
            This function queries the presence of the user currently authenticated to the Skype for Business UCWA. This does require that a presence is set first using Set-SfbClientContext.

            .Example
            Get-SfbClientContact
            
            Get the presence of the current user.
    #>
    [CmdletBinding()]
    Param (
        # The Skype for Business application context to send the message in.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }
    
    $myPresenceUri = '{0}{1}{2}' -f $Context.rootUri, $Context.application._embedded.me._links.self.href, '/presence'
    Try {
        $myPresence = Invoke-RestMethod -Method Get -Uri $myPresenceUri @rest -ErrorAction stop
    }
    Catch {
        If(($_.ErrorDetails.Message | ConvertFrom-Json).subcode -eq 'MakeMeAvailableRequired') {
            Throw "You need to first call Set-SfbClientPresence before you can call Get-SfbClientPresence"
        }
        Else {
            Throw $_
        }
    }
    
    $myPresence.availability
}