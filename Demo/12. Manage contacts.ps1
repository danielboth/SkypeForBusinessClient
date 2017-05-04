# Create application context for Daniel
New-SfBClientContext -SipDomain poshboth.nl -Credential $dcred

# Create group
New-SfbClientGroup -Name PSConf

# Add a member to the group
Add-SfbClientGroupMember -Name PSConf -Members Marco

# Create a second group
New-SfbClientGroup -Name Group2

# Add members to the second group
Add-SfbClientGroupMember -Name 'Group2' -Members Marco,Skype -Verbose

# Remove the contact (from the group)
Remove-SfbClientGroupMember -Name Group2 -Members Marco

# Remove a contact from the contact list
Remove-SfbClientGroupMember -Members Skype

# Remove the group
Remove-SfbClientGroup -Name PSConf

# Remove the second group
Remove-SfbClientGroup -Name Group2

# Remove the last contact
Remove-SfbClientGroupMember -Members Marco

# Stop the application
Remove-SfbClientContext