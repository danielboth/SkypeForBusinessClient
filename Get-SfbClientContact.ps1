function Get-SfbClientContact {
    <#
            .Synopsis
            Get a Skype for Business Contact details

            .Description
            This function queries the Skype for Business addressbook for contact details and returns them. There is a limit of 100 results and the function defaults to 10 results.

            .Example
            Get-SfbClientContact -Name 'Foo'
            
            Get's all the contacts from the addressbook that match the name Foo

            .Example
            Get-SfbClientContact -Name 'sip:foo@organisation.com'
            
            Get's the contact information for the user with the SIP address sip:foo@organisation.com
    #>

    [CmdletBinding()]
    param (
        # Name of the contact (Partial name is also allowed)
        [Parameter(Mandatory)]
        [String]$Name,
        
        # The limit to the number of users returns, range 1-100, defaults to 10.
        [Parameter()]
        [ValidateRange(0,100)]
        $Limit = 10,
    
        # The Skype for Business application context
        [Parameter()]
        [Object]$Context = $SkypeForBusinessClientModuleContext
    )
    
    
    $rest = @{
        ContentType = 'application/json'
        Headers = $Context.authHeader
    }
    
    $searchUri = $Context.rootUri + $Context.application._embedded.people._links.search.href
    $searchQuery = '?limit={0}&query={1}' -f $Limit,$Name
    
    $contacts = Invoke-RestMethod -Uri ($searchUri + $searchQuery) -Method Get @rest
    
    If($contacts.moreResultsAvailable) {
        Write-Warning 'More search results are available, please narrow your search or increase the number of returned results.'
    }
    
    $contacts._embedded.contact | ForEach-Object {
        Invoke-RestMethod -Method Get -Uri ($Context.rootUri + $_._links.self.href) @rest | ForEach-Object {
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
}