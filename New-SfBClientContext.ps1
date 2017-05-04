function New-SfBClientContext {
    <#
            .Synopsis
            Creates a new Skype for Business Application Context

            .Description
            This function is the starting point of the SkypeForBusinessClient Module. It sets up a Skype for Business UCWA application for the user to work with.
            All other functions in the SkypeForBusinessClient module rely on this function to be executed first. The output is a SkypeForBusinessClientModuleContext, which must be used as input for all other functions.

            The SkypeForBusinessClientModuleContext is created as a global variable, so users of the module won't have to manually supply the context to every function.

            The context can be removed using Remove-SfbClientContext, always do this as this disposes the runspaces spinned up by the SkypeForBusinessClient module.

            .Example
            New-SfBClientContext -SipDomain 'your.domain.com' -Credential $skypeCred
            
            This example creates a new SkypeForBusinessClientContext for the SipDomain your.domain.com using the credentials stored in $skypeCred, $skypeCred was created using Get-Credential. 
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Low')]
    param (
        # The SIP Domain to connect to
        [Parameter(Mandatory)]
        [String]$SipDomain,
        
        # The credential used to authenticate to Skype for Business
        [Parameter(Mandatory)]
        [pscredential]$Credential
    )
    
    $json = 'application/json'
    
    $autoDiscoverUri = 'https://lyncdiscoverinternal.{0}' -f $SipDomain
    $discovery = Invoke-RestMethod -Uri $autoDiscoverUri -ContentType $json -ErrorAction SilentlyContinue
    
    If(-not($discovery)) {
        Try {
            $autoDiscoverUri = 'https://lyncdiscover.{0}' -f $SipDomain
            $discovery = Invoke-RestMethod -Uri $autoDiscoverUri -ContentType $json -ErrorAction Stop
        }
        Catch {
            Throw "Autodiscovery of Skype for Business failed. Error: $_"
        }
    }
    
    $rootUri = ([System.Uri]$discovery._links.self.href).AbsoluteUri.Replace((([System.Uri]$discovery._links.self.href).PathAndQuery),$null)


    $ticketUri = "$rootUri/WebTicket/oauthtoken" 
    $authBody = @{
        grant_type = 'urn:microsoft.rtc:windows'
    }

    Try {
        $userAuth = Invoke-RestMethod -Uri $ticketUri -Body $authBody -Method Post -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -Credential $Credential -ErrorAction Stop
    }
    Catch {
        Throw "Authentication failed: $_"
    }
    $token = $userAuth

    $authHeader = [hashtable]::Synchronized(@{
            Authorization = "$($token.token_type) $($token.access_token)"
    })

    Try {
        $userResponse = Invoke-RestMethod -Uri $discovery._links.user.href -Headers $authHeader -ContentType $json -ErrorAction Stop
        $appUri = '{0}{1}' -f $rootUri,([System.Uri]$userResponse._links.applications.href).PathAndQuery
        $appGuid = "17ed5d75-40ce-400d-acdf-5a7f6f26af3b-$($env:USERNAME)"
        $appBody = ConvertTo-Json @{
            UserAgent = 'SkypeUcwa/PowerShell'
            EndpointId = $appGuid
            Culture = 'en-US'
        }
    }
    Catch {
        Throw "Failed to get Skype for Business application link. Error: $_"
    }

    Try {
        $application = Invoke-RestMethod -Uri $appUri -Headers $authHeader -Method Post -Body $appBody -ContentType $json -ErrorAction Stop
    }
    Catch {
        Throw "Failed to create Skype for Business application. Error: $_"
    }

    
    $global:SkypeForBusinessClientModuleContext = [pscustomobject]@{
        rootUri = $rootUri
        authHeader = $authHeader
        application = $application
        applicationUri = '{0}{1}' -f $rootUri,$application._links.self.href
        events = [hashtable]::Synchronized(@{
                next = $application._links.events.href
        })
        conversations = [hashtable]::Synchronized(@{})
    }
    
    $incomingMessages = [system.collections.arraylist]::Synchronized((New-Object System.Collections.Arraylist))
    $eventRunspace = [runspacefactory]::CreateRunspace()
    $eventRunspace.ApartmentState = 'STA'
    $eventRunspace.ThreadOptions = 'ReuseThread'          
    $eventRunspace.Open()
    
    # Skype Client Specific
    $eventRunspace.SessionStateProxy.SetVariable('SkypeForBusinessClientModuleContext',$SkypeForBusinessClientModuleContext)
    $eventRunspace.SessionStateProxy.SetVariable('incomingMessages',$incomingMessages)

    $psCmd = [PowerShell]::Create().AddScript({
            Import-Module C:\Repositories\SkypeForBusinessClient\SkypeForBusinessClient.psd1
            
            $rest = @{
                ContentType = 'application/json'
                Headers = $SkypeForBusinessClientModuleContext.authHeader
            }
            $run = $true
            
            Do {
                Try {
                    $event = Get-SfBClientEvent -TimeOut 180 -Context $SkypeForBusinessClientModuleContext -ErrorAction Stop
                    
                    # Process incoming messages
                    $event.sender.events | Where-Object{$_.link.rel -eq 'message' -and $_._embedded.message.direction -eq 'Incoming'} | ForEach-Object {
                    
                        $senderSipAddress = ('{0}{1}' -f 'sip:' , $_._embedded.message._links.participant.href.Split('/')[-1] )
                        [System.Threading.Monitor]::Enter($incomingMessages.syncroot)
                        
                        $incomingMessages.Add(
                            [pscustomobject]@{
                                conversationId = $_._embedded.message._links.messaging.href
                                from = $_._embedded.message._links.participant.title                                    
                                sipAddress = $senderSipAddress
                                timeStamp = ($_._embedded.message.timeStamp).ToLocalTime()
                                plainMessage = [System.Net.WebUtility]::UrlDecode(($_._embedded.message._links.plainMessage.href).Split(',')[1])
                            }
                        )
                        [System.Threading.Monitor]::Exit($incomingMessages.syncroot)    
                    }
                    
                    # Process incoming conversation invitations (auto-accept)
                    $event.sender.events | Where-Object {
                            $_.link.rel -eq 'messagingInvitation' -and 
                            $_._embedded.messagingInvitation.direction -eq 'Incoming' -and 
                            $_.type -ne 'completed' -and $_._embedded.messagingInvitation._links.accept.href} | ForEach-Object {
                            
                                $acceptUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri, $_._embedded.messagingInvitation._links.accept.href
                                $sipAddress = $_._embedded.messagingInvitation._embedded.from.uri
                                $conversationUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri, $_._embedded.messagingInvitation._links.messaging.href
                        
                                Try {
                                    Invoke-RestMethod -Method Post -Uri $acceptUri @rest -ErrorAction Stop
                                }
                                Catch {
                                    Write-Error $_
                                }
                        
                                $SkypeForBusinessClientModuleContext.conversations[$sipAddress] = $conversationUri

                            }
                    
                    # Process deleted conversations
                    $event.sender.events | Where-Object {$_.link.rel -eq 'messaging' -and $_.reason.subcode -eq 'Ended'} | ForEach-Object {
                        $conversationUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri, $_.link.href 
                        
                        $removedConversation = $SkypeForBusinessClientModuleContext.conversations.GetEnumerator() | Where-Object {$_.Value -eq $conversationUri}
                        $SkypeForBusinessClientModuleContext.conversations.Remove($removedConversation.Key)
                    }
                }
                Catch {
                    Write-Error $_
                    $run = $false
                }
            }
            While($run)
    })
    $psCmd.Runspace = $eventRunspace
    $eventHandle = $psCmd.BeginInvoke()

    $tokenExpiryMonitorRunspace = [runspacefactory]::CreateRunspace()
    $tokenExpiryMonitorRunspace.ApartmentState = 'STA'
    $tokenExpiryMonitorRunspace.ThreadOptions = 'ReuseThread'          
    $tokenExpiryMonitorRunspace.Open()

    # Skype Client Specific
    $tokenExpiryMonitorRunspace.SessionStateProxy.SetVariable('Credential',$Credential)
    $tokenExpiryMonitorRunspace.SessionStateProxy.SetVariable('SkypeForBusinessClientModuleContext',$SkypeForBusinessClientModuleContext)
    $tokenExpiryMonitorRunspace.SessionStateProxy.SetVariable('token',$token)
    
    $tokenExpirationMonitorCmd = [PowerShell]::Create().AddScript({

        Do{
            $tokenLifetime = New-TimeSpan -Seconds $token.expires_in
            $renewTokenInTimeSpan = $tokenLifetime - (New-TimeSpan -Seconds 300)

            Start-Sleep -Seconds $renewTokenInTimeSpan.Seconds

            $ticketUri = "$($SkypeForBusinessClientModuleContext.rootUri)/WebTicket/oauthtoken" 
            $authBody = @{
                grant_type = 'urn:microsoft.rtc:windows'
            }

            Try {
                $userAuth = Invoke-RestMethod -Uri $ticketUri -Body $authBody -Method Post -ContentType 'application/x-www-form-urlencoded;charset=UTF-8' -Credential $Credential -ErrorAction Stop
            }
            Catch {
                Throw "Authentication failed: $_"
            }
            $token = $userAuth

            $SkypeForBusinessClientModuleContext.authHeader['Authorization'] = "$($token.token_type) $($token.access_token)"
        }
        While($true)

    })
    $tokenExpirationMonitorCmd.Runspace = $tokenExpiryMonitorRunspace
    $tokenExpirationMonitorHandle = $tokenExpirationMonitorCmd.BeginInvoke()

    $SkypeForBusinessClientModuleContext | Add-Member -MemberType NoteProperty -Name backgroundProcesses -Value $null
    $SkypeForBusinessClientModuleContext | Add-Member -MemberType NoteProperty -Name incomingMessages -Value $incomingMessages
    
    $SkypeForBusinessClientModuleContext.backgroundProcesses = [system.collections.arraylist]::Synchronized((New-Object System.Collections.Arraylist))
    
    $null = [System.Threading.Monitor]::Enter($SkypeForBusinessClientModuleContext.backgroundProcesses.syncroot)
    $null = $SkypeForBusinessClientModuleContext.backgroundProcesses.Add(
        [pscustomobject]@{
            Name = "EventRunspace"
            Handle = $eventHandle
            Runspace = $psCmd
        }
    )

    $null = $SkypeForBusinessClientModuleContext.backgroundProcesses.Add(
        [pscustomobject]@{
            Name = "tokenExpirationMonitorRunspace"
            Handle = $tokenExpirationMonitorHandle
            Runspace = $tokenExpirationMonitorCmd
        }
    )
    $null = [System.Threading.Monitor]::Exit($SkypeForBusinessClientModuleContext.backgroundProcesses.syncroot) 
    
    Write-Output $SkypeForBusinessClientModuleContext
}