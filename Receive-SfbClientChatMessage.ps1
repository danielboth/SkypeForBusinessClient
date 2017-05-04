Function Receive-SfbClientChatMessage {
    <#
            .Synopsis
            Receive incoming Skype for Business client messages

            .Description
            This function takes messages from the incoming message queue on the SkypeForBusinessClientContext, outputs them and removes them from the queue.

            .Example
            Receive-SfbClientChatMessage -SipAddress 'sip:Foo@organisation.com'

            Receives the messages send by sip:foo@organisation.com
    #>
    [CmdletBinding()]
    Param (
        # The conversationId to receive messages for
        [Parameter(
                Mandatory,
                ValueFromPipelineByPropertyName,
                ParameterSetName = 'ConversationId'
        )]
        [string]$ConversationId,
        
        # The sipAddress to receive messages for
        [Parameter(
                Mandatory,
                ValueFromPipelineByPropertyName,
                ParameterSetName = 'SipAddress'
        )]
        [string]$SipAddress,
        
        # Switch to keep messages in Skype For Business Context instead of removing them from the incoming messages
        [Parameter()]
        [switch]$Keep,
        
        # The Skype for Business application context in which to receive messages
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )

    $incomingMessages = $Context.incomingMessages
    If($SipAddress) {
        $conversationId = ($incomingMessages.Where({$_.sipAddress -eq $SipAddress}) | Select-Object -Last 1).conversationId
    }
    
    $incomingMessages.Where({$_.conversationId -eq $ConversationId}) | ForEach-Object {
        $_
        
        If(-not($Keep)){
            $null = [System.Threading.Monitor]::Enter($incomingMessages.syncroot)
            $null = $incomingMessages.Remove($_)
            $null = [System.Threading.Monitor]::Exit($incomingMessages.syncroot)  
        }
    }
}