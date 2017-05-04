# Start a new application
New-SfBClientContext -SipDomain poshboth.nl -Credential $mcred

# Set presence
Set-SfbClientPresence -Availability Online

# Send a message
Get-SfbClientContact -Name Daniel | Send-SfbClientChatMessage -Message 'Hello PSConf!'

# Check incoming messages:
$SkypeForBusinessClientModuleContext.incomingMessages

# Have a look at the background processes:
$SkypeForBusinessClientModuleContext.backgroundProcesses

# Look at active conversations (and close conversation)
$SkypeForBusinessClientModuleContext.conversations

# Stop the application
Remove-SfbClientContext