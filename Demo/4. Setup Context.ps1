$SkypeForBusinessClientModuleContext = [pscustomobject]@{
    rootUri = $rootUri
    authHeader = $authHeader
    application = $application
    applicationUri = '{0}{1}' -f $rootUri,$application._links.self.href
    events = [hashtable]::Synchronized(@{
            next = $application._links.events.href
    })
    conversations = [hashtable]::Synchronized(@{})
}


#Next events:
$application._links