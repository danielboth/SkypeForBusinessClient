$SipDomain = 'poshboth.nl'
$json = 'application/json'
    
$autoDiscoverUri = 'https://lyncdiscoverinternal.{0}' -f $SipDomain
$discovery = Invoke-RestMethod -Uri $autoDiscoverUri -ContentType $json -ErrorAction SilentlyContinue
    
If(-not($discovery)) {
    Try {
        $autoDiscoverUri = 'https://lyncdiscover.{0}' -f $SipDomain
        $discovery = Invoke-RestMethod -Uri $autoDiscoverUri -ContentType $json -ErrorAction Stop
    }
    Catch {
        Throw "Autodiscovery of Skype for Business failed. Error: $_"
    }
}

$discovery._links | Format-List

$rootUri = ([System.Uri]$discovery._links.self.href).AbsoluteUri.Replace((([System.Uri]$discovery._links.self.href).PathAndQuery),$null)

$rootUri