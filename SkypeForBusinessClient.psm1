param (
    [bool]$IsDebug = $false
)

foreach ($item in Get-ChildItem -Path $PSScriptRoot\*.ps1) {
    if ($IsDebug) {
        # Performance is not important...
        . $item.FullName
    } else {
        # InvokeScript(useLocalScope, scriptBlock, input, args)
        $ExecutionContext.InvokeCommand.InvokeScript(
            $false, 
            (
                [scriptblock]::Create(
                    [io.file]::ReadAllText(
                        $item.FullName
                    )
                )
            ), 
            $null, 
            $null
        )
    }
}

