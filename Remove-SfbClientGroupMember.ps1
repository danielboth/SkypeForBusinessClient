Function Remove-SfbClientGroupMember {
    <#
            .Synopsis
            Remove a contact from a Skype for Business Client Group

            .Description
            This function removes the members from a Skype for Business Client Group. The default group is Other Contacts, but you can also use Favorites or a custom group you created using New-SfbClientGroup.

            .Example
            Remove-SfbClientGroupMember -Members 'Contact Name'
            
            This example Removes the member 'Contact Name' from all groups

            .Example
            Remove-SfbClientGroupMember -Members 'sip:Removeress@outsideorganisation.com'
            
            This example Removes a member based on SIP Removeress from all groups
    #>
    Param (
        # The name of the group to remove the member from, default is all groups
        [Parameter()]
        [string]$Name,

        # The list of members to remove from all groups in Skype for Business
        [Parameter(Mandatory)]
        [string[]]$Members,
        
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }

    $removeGroupMembershipUri = '{0}{1}' -f $context.applicationUri, '/people/groupmemberships/removeContactFromAllGroups'

    $Members | ForEach-Object {
        Try {
            $member = Get-SfbClientContact -Name $_ -ErrorAction Stop
    
            If($member.count -gt 1 -or $member.count -eq 0) {
                Write-Error "Member $_ could not be identified"
            }
            Else {
                If(-not([string]::IsNullOrEmpty($Name))) {
                    $allCurrentGroups = Get-SfbClientGroup | Where-Object {$_.members.uri -contains $member.sipAddress}
                    $reAddToGroups = $allCurrentGroups | Where-Object {$_.name -ne $Name}
                }
            
                $removeContactUri = '{0}{1}{2}' -f $removeGroupMembershipUri,'?contactUri=', [System.Net.WebUtility]::UrlEncode($member.sipAddress)
                $null = Invoke-RestMethod -Uri $removeContactUri -Method Post @rest

                If($reAddToGroups) {
                    $reAddToGroups | ForEach-Object {
                        Add-SfbClientGroupMember -Name $_.name -Members $member.sipAddress
                    }
                }
            }
        }
        Catch {
            Write-Error "Failed to remove member from all groups: $_"
        }
    }
}