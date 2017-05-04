$Name = 'Marco'
$Limit = 10

$rest = @{
    ContentType = 'application/json'
    Headers = $SkypeForBusinessClientModuleContext.authHeader
}
    
$searchUri = $SkypeForBusinessClientModuleContext.rootUri + $SkypeForBusinessClientModuleContext.application._embedded.people._links.search.href
$searchQuery = '?limit={0}&query={1}' -f $Limit,$Name
    
$contacts = Invoke-RestMethod -Uri ($searchUri + $searchQuery) -Method Get @rest
$contacts._embedded


    
If($contacts.moreResultsAvailable) {
    Write-Warning 'More search results are available, please narrow your search or increase the number of returned results.'
}
    
$contacts._embedded.contact | ForEach-Object {
    Invoke-RestMethod -Method Get -Uri ($SkypeForBusinessClientModuleContext.rootUri + $_._links.self.href) @rest | ForEach-Object {
        [pscustomobject]@{
            name = $_.name
            sipAddress = $_.uri
            company = $_.company
            department = $_.department
            title = $_.title
            emailAddresses = $_.emailAddresses -join ';'
            workPhoneNumber = $_.workPhoneNumber
            type = $_.type
            sourceNetwork = $_.sourceNetwork
            _links = $_._links
        }
    }
}