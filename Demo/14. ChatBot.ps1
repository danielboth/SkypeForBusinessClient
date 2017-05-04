Remove-SfbClientContext
New-SfBClientContext -SipDomain poshboth.nl -Credential $scred
Set-SfbClientPresence -Availability Online

$DnsConversation = 1

Do {
    $incoming = $SkypeForBusinessClientModuleContext.incomingMessages.Clone()
    
    $message = $incoming | ForEach-Object {
        Receive-SfbClientChatMessage -ConversationId $_.conversationId
    }

    
    If($message) {
        switch ($conversation) {
            'DNSARecord' {

                switch ($dnsConversation) {
                    1 {
                        $recordName = $message.plainMessage
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Ok, I've $($message.plainMessage) as the record name, what is the name of the zone to create this record in?"
                        $dnsConversation = 2
                    }
                    2 {
                        $zoneName = $message.plainMessage
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Ok, I've $($message.plainMessage) as the zone name, what is the IP address of the record?"
                        $dnsConversation = 3
                    }
                    3 {
                        $ipAddress = $message.plainMessage
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "I'll create the record $RecordName in zone $zoneName with IP Address $ipAddress. Is that correct? (yes/no)"
                        $dnsConversation = 4
                    }
                    4 {
                        If($message.plainMessage -match 'yes') {
                            Try {
                                Add-DnsServerResourceRecordA -Name $recordName -IPv4Address $ipAddress -ZoneName $zoneName -ErrorAction Stop
                                Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message 'Successfully created the DNS record!'
                            }
                            Catch {
                                Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "I encountered an error during the creation of the record, the error was: $_"
                            }
                            Finally {
                                $conversation = $null
                                $DnsConversation = 1
                            }
                        }
                        else {
                            Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Ok, I cancelled the creation of the DNS record"
                            $conversation = $null
                            $DnsConversation = 1
                        }
                    }
                }
            }

            default {
                switch -Regex ($message.plainMessage) {
                    'Hey Bot' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Hey"
                    }
                    'polite' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Sorry! Good morning PS Conf EU! :D:D:D"
                    }
                    'repeat this' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Repeating your message: $(($message.plainMessage -split ':')[-1])"
                    }
                    '^Write file:' {
                        $Content = $message.plainMessage.Replace('Write file:',$null)
                        Try {
                            Add-Content -Path C:\repositories\SkypeForBusinessClient\Demo\SkypeBotFile.txt -Value $Content -ErrorAction Stop
                            Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Added content to file!"
                        }
                        Catch {
                            Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Failed to add content to file!"
                        }
                    }
                    'Create DNS A Record' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "I can create a DNS A record for you, what's the name of the record?"
                        $Conversation = 'DNSARecord'
                    }
                    'Thank you' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "You're welcome!"
                    }
                    'next demo' {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Well, we didn't discuss the persistent chat beast yet..."
                    }
                    default {
                        Send-SfbClientChatMessage -SipAddress $message.sipAddress -Message "Sorry I didn't understand that, can you rephrase please?"
                    }
                }
            }
        }
    }
    
    Start-Sleep -Milliseconds 500
}
While ($true)