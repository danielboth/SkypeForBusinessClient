Function Remove-SfbClientGroup {
    <#
            .Synopsis
            Removes a new Skype for Business Client Group

            .Description
            In the Skype for Business client you can create custom groups to organize your contacts. This function enables you to remove these groups.

            .Example
            Remove-SfbClientGroup -Name 'MyNewCustomGroup'

            Removes the group MyNewCustomGroup
    #>
    [CmdletBinding()]
    param (
        # The name of the new group.
        [Parameter(Mandatory)]
        [String]$Name,
        
        # The Skype for Business application context in which to remove the new group.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $versionHeader = $context.authHeader.Clone()
    $versionHeader.Add('X-MS-RequiresMinResourceVersion', 2)
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $versionHeader
    }
    
    $myGroupsUri = '{0}/{1}' -f $context.rootUri,$Context.application._embedded.people._links.myGroups.href
    $myGroups = Invoke-RestMethod -Method Get -Uri $myGroupsUri @rest
    
    $deleteGroupId = $myGroups._embedded.group | Where-Object {$_.name -eq $Name} | Select-Object -ExpandProperty Id
    
    If(-not($deleteGroupId)) {
        Write-Error "Group $name could not be deleted: Group not found"
    }
    Else {
        $groupDeleteUri = '{0}{1}/{2}' -f $context.rootUri, $context.application._embedded.people._links.myGroups.href, $deleteGroupId
        
        $null = Invoke-RestMethod -Uri $groupDeleteUri -Method Delete @rest
    }
}