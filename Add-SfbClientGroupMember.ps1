Function Add-SfbClientGroupMember {
    <#
            .Synopsis
            Add a contact to a Skype for Business Client Group

            .Description
            This function manages the members of a Skype for Business Client Group. The default group is Other Contacts, but you can also use Favorites or a custom group you created using New-SfbClientGroup.

            .Example
            Add-SfbClientGroupMember -Name 'Other Contacts' -Members 'Contact Name'
            
            This example adds the member 'Contact Name' to the group Other Contacs.

            .Example
            Add-SfbClientGroupMember -Name 'CustomGroup' -Members 'sip:address@outsideorganisation.com'
            
            This example adds a member based on SIP address to the group CustomGroup.
    #>
    
    [CmdletBinding()]
    param (
        # The name of the group, use Other Contacts for the default group
        [Parameter(Mandatory)]
        [String]$Name,
        
        # The name of the member to add, this name needs to be uniquely identified in the Skype for Business infrastructure. Adding remote (outside the organisation) contacts can be done using sipaddress.
        [Parameter(Mandatory)]
        [String[]]$Members,
        
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
        ErrorAction = 'Stop'
    }

    $groupMembershipUri = '{0}{1}' -f $context.applicationUri, '/people/groupmemberships'

    If($Name -ne 'Other Contacts') {
        Try {
            $groupId = Get-SfbClientGroup -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty id
        }
        Catch {
            Throw "Unable to find group $Name. Error: $_"
        }
    }

    $Members | ForEach-Object {
        Try {
            $member = Get-SfbClientContact -Name $_ -ErrorAction Stop
    
            If($member.count -gt 1 -or $member.count -eq 0) {
                Write-Error "Member $_ could not be identified"
            }
            Else {
                $addContactUri = '{0}{1}{2}' -f $groupMembershipUri,'?contactUri=', [System.Net.WebUtility]::UrlEncode($member.sipAddress)
                If($groupId) {
                    $addContactUri = '{0}{1}{2}' -f $addContactUri, '&groupId=', $groupId
                }
            
                $null = Invoke-RestMethod -Uri $addContactUri -Method Post @rest
            }
        }
        Catch {
            Write-Error "Failed to add member to group: $_"
        }
    }
}