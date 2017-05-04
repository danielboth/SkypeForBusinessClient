Function Set-SfbClientPresence {
    <#
            .Synopsis
            Set Skype for Business presence

            .Description
            This function will call the MakeMeAvailable function in UCWA if it's the first time this function was called within the context. This allows the user to receive messages. Next to that,
            the module will start a runspace to post to the reportMyActivity interface of UCWA to keep the user active.

            If the user is already available (MakeMeAvailable was called before) then it just changes the presence of the user.

            .Example
            Set-SfbClientPresence -Availability Online

            Set's the user online.
    #>
    [CmdletBinding()]
    Param (
        # 
        [Parameter(Mandatory)]
        [ValidateSet('Online','Away','BeRightBack','Busy','DoNotDisturb','Offline')]
        $Availability,
    
        # The Skype for Business application context to send the message in.
        [Parameter()]
        [object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }
    
    $makeMeAvailable = $false
    $myPresenceUri = '{0}{1}{2}' -f $Context.rootUri, $Context.application._embedded.me._links.self.href, '/presence'
    
    Try {
        $myPresence = Invoke-RestMethod -Method Get -Uri $myPresenceUri @rest -ErrorAction stop
    }
    Catch {
        If(($_.ErrorDetails.Message | ConvertFrom-Json).subcode -eq 'MakeMeAvailableRequired') {
            $makeMeAvailable = $true
        }
    }
    
    If($makeMeAvailable) {
        $makeMeAvailableUri = '{0}{1}' -f $Context.rootUri, $Context.application._embedded.me._links.makeMeAvailable.href
        $makeMeAvailableBody = ConvertTo-Json @{
            signInAs = $availability
            supportedMessageFormat = 'Plain'
            supportedModalities = @('Messaging')
        }
    
        Try {
            $null = Invoke-RestMethod -Method Post -Uri $makeMeAvailableUri -Body $makeMeAvailableBody @rest -ErrorAction Stop
        
            $reportMyActivityRunspace = [runspacefactory]::CreateRunspace()
            $reportMyActivityRunspace.ApartmentState = 'STA'
            $reportMyActivityRunspace.ThreadOptions = 'ReuseThread'          
            $reportMyActivityRunspace.Open()
    
            # Skype Client Specific
            $reportMyActivityRunspace.SessionStateProxy.SetVariable('SkypeForBusinessClientModuleContext',$Context)

            $psCmd = [PowerShell]::Create().AddScript({
                    $reportMyActivityUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.applicationUri, '/reportMyActivity'
                    
                    While($true) {
                        Invoke-RestMethod -Uri $reportMyActivityUri -Method Post -Headers $SkypeForBusinessClientModuleContext.authHeader
                        Start-Sleep -Seconds 120
                    }
            })
        
            $psCmd.Runspace = $reportMyActivityRunspace
            $reportMyActivityHandle = $psCmd.BeginInvoke()
        
            $null = [System.Threading.Monitor]::Enter($Context.backgroundProcesses.syncroot)
            $null = $Context.backgroundProcesses.Add(
                [pscustomobject]@{
                    Name = "reportMyActivityRunspace"
                    Handle = $reportMyActivityHandle
                    Runspace = $psCmd
                }
            )
            $null = [System.Threading.Monitor]::Exit($Context.backgroundProcesses.syncroot)
        }
        Catch {
            Throw "MakeMeAvailable call failed. Error: $_"
        }
        
        # Get the updated application resource
        $null = Invoke-RestMethod -Method Get -Uri $Context.applicationUri @rest
    }
    else {
        $myPresenceBody = ConvertTo-Json @{
            availability = $availability
        }
        
        $null = Invoke-RestMethod -Method Post -Uri $myPresenceUri -Body $myPresenceBody @rest
    }
}