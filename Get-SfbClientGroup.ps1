function Get-SfbClientGroup {
    <#
            .Synopsis
            Get Skype for Business Client group details

            .Description
           This function queries the Skype for Business client group details and returns the Name, Id and members of the group.

            .Example
            Get-SfbClientGroup
            
            Returns all Skype for Business client groups created.

            .Example
            Get-SfbClientGroup -Name 'Other Contacts'

            This returns the details (Name, Id and members) of the group Other Contacts.
    #>
    param (
        # The name of the group
        [Parameter()]
        [String]$Name,
    
        # The Skype for Business application context in which to query for the group.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }
    
    $myGroupsUri = '{0}/{1}' -f $context.rootUri,$Context.application._embedded.people._links.myGroups.href
    $myGroups = Invoke-RestMethod -Method Get -Uri $myGroupsUri @rest

    # Three items to return: pinnedGroup (Favorites), defaultGroup (Other Contacts by default) and group

    [array]$allMyGroups = 'pinnedGroup','defaultGroup' | ForEach-Object {
    
        $groupMemberUri = '{0}/{1}' -f $Context.rooturi,$myGroups._embedded.$_._links.groupContacts.href
        [pscustomobject]@{
            name = $myGroups._embedded.$_.name
            id =  $myGroups._embedded.$_.id
            members = (Invoke-RestMethod -Method Get -Uri $groupMemberUri @rest)._embedded.contact
        }
    }

    $allMyGroups += $myGroups._embedded.group | ForEach-Object {

        $groupMemberUri = '{0}/{1}' -f $Context.rooturi,$_._links.groupContacts.href
        [pscustomobject]@{
            name = $_.name
            id =  $_.id
            members = (Invoke-RestMethod -Method Get -Uri $groupMemberUri @rest)._embedded.contact
        }
    }
    
    If($Name) {
         Write-Output $allMyGroups | Where-Object {$_.name -eq $Name}
    }
    Else {
        Write-Output $allMyGroups
    }
}
    
