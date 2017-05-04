function Remove-SfbClientContext {
    <#
            .Synopsis
            Removes an Skype for Business Client Context created by New-SfbClientContext

            .Description
            This function deletes the Skype for Business UCWA application and disposes all runspaces started by functions in the SkypeForBusinessClient module.

            .Example
            Remove-SfbClientContext
            
            Remove the context stored in $SkypeForBusinessClientModuleContext
    #>

    [CmdletBinding()]
    param (

        # The Skype for Business application context
        [Parameter()]
        [Object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    $json = 'application/json'
    $rest = @{
        ContentType = $json
        Headers = $Context.authHeader
    }
    
    $applicationContextUri = '{0}{1}' -f $context.rootUri,$context.application._links.self.href
    
    Try {
        $null = Invoke-RestMethod -Uri $applicationContextUri -Method Delete @rest -ErrorAction Stop
        
        $null = $Context.backgroundProcesses.Runspace | ForEach-Object {$_.Stop()}
        $null = $Context.backgroundProcesses.Runspace | ForEach-Object {$_.Dispose()}
        
        $Global:SkypeForBusinessClientModuleContext = $null
    }
    Catch {
        Write-Warning "Failed to remove SkypeForBusinessClient Context: $_"
    }
}