$Name = 'Daniel'
$json = 'application/json'

$userPresence = Get-SfbClientContact -Name $Name -Context $SkypeForBusinessClientModuleContext -PipelineVariable contact | ForEach-Object {
    $presenceUri = '{0}{1}' -f $SkypeForBusinessClientModuleContext.rootUri,$_._links.contactPresence.href
    Invoke-RestMethod -Method Get -Uri $presenceUri -ContentType $json -Headers $SkypeForBusinessClientModuleContext.authHeader | ForEach-Object {
        [pscustomobject]@{
            name = $contact.Name
            availability = $_.availability
            deviceType = $_.deviceType
            lastActive = $_.lastActive
        }
    }
}
            
Write-Output $userPresence