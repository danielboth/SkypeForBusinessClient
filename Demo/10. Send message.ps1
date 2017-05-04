$Message = 'Hi there PSCONFEU!'

Try {
    $conversation = Invoke-RestMethod -Method Get -Uri $conversationUri @rest -ErrorAction Stop
}
Catch {
    If(($_.ErrorDetails.Message | ConvertFrom-Json).code -eq 'NotFound') {
        $conversationUri = Start-SfbClientChatMessaging -requestBody $requestBody -Context $SkypeForBusinessClientModuleContext
        $conversation = Invoke-RestMethod -Method Get -Uri $conversationUri @rest -ErrorAction Stop
    }
    Else {
        Throw $_
    }
}
    
$sendMessageUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri,($conversation._links.sendMessage.href)
    
$messageBody = $Message
$null = Invoke-RestMethod -Method Post -UseBasicParsing $sendMessageUri -ContentType 'text/plain;charset=UTF-8' -Headers $SkypeForBusinessClientModuleContext.authHeader -Body $messageBody
    
$SkypeForBusinessClientModuleContext.conversations[$SipAddress] = $conversationUri