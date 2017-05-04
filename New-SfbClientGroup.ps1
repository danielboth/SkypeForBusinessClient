Function New-SfbClientGroup {
    <#
            .Synopsis
            Create a new Skype for Business Client Group

            .Description
            In the Skype for Business client you can create custom groups to organize your contacts. This function enables you to create these groups.

            .Example
            New-SfbClientGroup -Name 'MyNewCustomGroup'

            Creates the group MyNewCustomGroup
    #>
    [CmdletBinding()]
    param (
        # The name of the new group.
        [Parameter(Mandatory)]
        [String]$Name,
        
        # The Skype for Business application context in which to create the new group.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $versionHeader = $context.authHeader.Clone()
    $versionHeader.Add('X-MS-RequiresMinResourceVersion', 2)
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $versionHeader
        ErrorAction = 'Stop'
    }

    $groupsUri = '{0}{1}' -f $context.rootUri,$context.application._embedded.people._links.myGroups.href
    
    $body = ConvertTo-Json @{
        displayName = $Name
    }
    
    Try {
        $null = Invoke-RestMethod -Method Post -Uri $groupsUri -Body $body @rest
    }
    Catch {
        Throw "Creating new Skype for Business group $Name failed: $_"
    }
}