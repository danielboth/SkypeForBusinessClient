$SkypeForBusinessClientModuleContext.conversations.Remove('sip:daniel@poshboth.nl')
Function Start-SfbClientChatMessaging {
    Param (
        # The body of the request to startMessaging
        [Parameter(Mandatory)]
        [string]$requestBody,
    
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
        $null = Get-SfBClientEvent -TimeOut 180 -Context $Context
        $event = ($Context.events.Clone().GetEnumerator() | 
            Sort-Object Key -Descending).Value | 
            Select-Object -First 2 | 
            Where-Object {$_.sender.events._embedded.messaging._links.sendmessage.href} 

        Start-Sleep -Milliseconds 100
    }
    Until ($event)
        
    $conversationUri = '{0}{1}' -f $context.rootUri, ($event.sender.events._embedded.messaging._links.sendmessage.href -replace '/messages$')
    Write-Output $conversationUri
}

$SipAddress = 'sip:daniel@poshboth.nl'
$rest = @{
    ContentType = 'application/json'
    Headers = $SkypeForBusinessClientModuleContext.authHeader
} 
    
$requestBody = ConvertTo-Json @{
    operationId = $SkypeForBusinessClientModuleContext.application._embedded.communication.psobject.Properties | 
                    Where-Object{$_.Value -like 'please pass this*'} | 
                    Select-Object -ExpandProperty Name
    to = $SipAddress
}
    
If(-not($SkypeForBusinessClientModuleContext.conversations[$SipAddress])) {
    $conversationUri = Start-SfbClientChatMessaging -requestBody $requestBody -Context $SkypeForBusinessClientModuleContext
        
    #$conversationUri = $context.rootUri + ($webRequest.RawContent -replace '[\s\S]*Location:\s(.*)[\s\S]*','$1')
}
Else {
    $conversationUri = $SkypeForBusinessClientModuleContext.conversations[$SipAddress]
}
