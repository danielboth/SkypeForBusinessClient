Function Send-SfbClientChatMessage {
    <#
            .Synopsis
            Send a message to a Skype for Business Contact

            .Description
            This function enables you to send a plaintext message to one of your Skype for Business contacts. If an ongoing conversation is found, we will continue that conversation. 
            Otherwise a new conversation will be started.

            .Example
            Get-SfbClientContact Name 'Foo Bar' | Send-SfbClientChatMessage -Message 'Good morning'

            Sends the message 'Good morning' to user Foo Bar
    #>
    [CmdletBinding()]
    Param (
        # The SipAddress of the user to send the message to.
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]
        [ValidatePattern('^sip:')]
        [string]$SipAddress,
        
        # The message to send
        [Parameter(Mandatory)]
        [string]$Message,
        
        # The Skype for Business application context to send the message in.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    Function Start-SfbClientChatMessaging {
        Param (
            # The Skype for Business application context to send the message in.
            [Parameter()]
            [object]$Context = $SkypeForBusinessClientModuleContext
        )
        
        $rest = @{
            ContentType = 'application/json'
            Headers = $Context.authHeader
        }
        
        Try {
            $messageUri = '{0}{1}' -f $Context.rootUri,$Context.application._embedded.communication._links.startMessaging.href
            $webRequest = Invoke-WebRequest -Method Post -Uri $messageUri @rest -Body $requestBody -ErrorAction Stop
        }
        Catch {
            Throw "Webrequest to messageUri $messageUri failed, message cannot be send. Error: $_"
        }
        
        Do {
            $event = ($Context.events.Clone().GetEnumerator() | 
                Sort-Object Key -Descending).Value | 
                Select-Object -First 3 | 
                Where-Object {$_.sender.events._embedded.messaging._links.sendmessage.href} 

            Start-Sleep -Milliseconds 100
        }
        Until ($event)
        
        $conversationUri = '{0}{1}' -f $context.rootUri, ($event.sender.events._embedded.messaging._links.sendmessage.href -replace '/messages$')
        Write-Output $conversationUri
    }
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    } 
    
    $requestBody = ConvertTo-Json @{
        operationId = $Context.application._embedded.communication.psobject.Properties | 
                        Where-Object{$_.Value -like 'please pass this*'} | 
                        Select-Object -ExpandProperty Name
        to = $SipAddress
    }
    
    If(-not($Context.conversations[$SipAddress])) {
        $conversationUri = Start-SfbClientChatMessaging -Context $Context
        
        #$conversationUri = $context.rootUri + ($webRequest.RawContent -replace '[\s\S]*Location:\s(.*)[\s\S]*','$1')
    }
    Else {
        $conversationUri = $Context.conversations[$SipAddress]
    }
    
    Try {
        $conversation = Invoke-RestMethod -Method Get -Uri $conversationUri @rest -ErrorAction Stop
    }
    Catch {
        If(($_.ErrorDetails.Message | ConvertFrom-Json).code -eq 'NotFound') {
            $conversationUri = Start-SfbClientChatMessaging -Context $Context
            $conversation = Invoke-RestMethod -Method Get -Uri $conversationUri @rest -ErrorAction Stop
        }
        Else {
            Throw $_
        }
    }
    
    $sendMessageUri = '{0}{1}' -f $Context.rootUri,($conversation._links.sendMessage.href)
    
    $messageBody = $Message
    $null = Invoke-RestMethod -Method Post -UseBasicParsing $sendMessageUri -ContentType 'text/plain;charset=UTF-8' -Headers $context.authHeader -Body $messageBody
    
    $Context.conversations[$SipAddress] = $conversationUri
}