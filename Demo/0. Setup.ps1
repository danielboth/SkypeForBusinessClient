Import-Module C:\repositories\SkypeForBusinessClient\SkypeForBusinessClient.psd1

$dcred = Get-Credential -Message 'Skype for Business Credential' -UserName 'poshboth\daniel'
$mcred = Get-Credential -Message 'Skype for Business Credential' -UserName 'poshboth\marco'
$scred = Get-Credential -Message 'Skype for Business Credential' -UserName 'poshboth\skype'