function Get-SfbClientContactPresence {
    <#
            .Synopsis
            Get the presence status of a contact

            .Description
            This function queries the presence of a Skype for Business Client contact. For example the presence can be Online, Away, BeRightBack, Busy, DoNotDisturb or Offline

            .Example
            Get-SfbClientContact -Name Foo | Get-SfbClientContactPresence

            This get's the presence of all users returned by the Get-SfbClientContact function.
    #>

    [CmdletBinding()]
    param (
        # The name of the contact
        [Parameter(
                Mandatory,
                ValueFromPipelineByPropertyName
        )]
        [String]$Name,
        
        # PresenceUri for the contact
        [Parameter(
                ValueFromPipelineByPropertyName
        )]
        [object]$_links,
        
        # The Skype for Business application context
        [Parameter()]
        [Object]$Context = $SkypeForBusinessClientModuleContext
    )
    Begin {
        $json = 'application/json'
    }
    
    Process {
        if($_links) {
            $presenceUri = '{0}{1}' -f $Context.rootUri,$_links.contactPresence.href
            Invoke-RestMethod -Method Get -Uri $presenceUri -ContentType $json -Headers $Context.authHeader | ForEach-Object { 
                [pscustomobject]@{
                    name = $Name
                    availability = $_.availability
                    deviceType = $_.deviceType
                    lastActive = $_.lastActive
                }
            }
        }
        else {
            $userPresence = Get-SfbClientContact -Name $Name -Context $Context -PipelineVariable contact | ForEach-Object {
                $presenceUri = '{0}{1}' -f $Context.rootUri,$_._links.contactPresence.href
                Invoke-RestMethod -Method Get -Uri $presenceUri -ContentType $json -Headers $Context.authHeader | ForEach-Object {
                    [pscustomobject]@{
                        name = $contact.name
                        availability = $_.availability
                        deviceType = $_.deviceType
                        lastActive = $_.lastActive
                    } 
                }
            }
            
            Write-Output $userPresence
        }
    }
}