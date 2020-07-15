function Find-FileInEnvPath {
    [CmdletBinding()]
    param (
        # Filename
        [Parameter(Mandatory)]
        [string]
        $FileName
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')

    [string[]]$pathsAll = $env:Path.Split(';').Where({$_}) | Select-Object -Unique
    [string[]]$pathsCombined = $pathsAll.ForEach({
        [System.IO.Path]::Combine($_, $FileName)
    })
    [string[]]$pathsExists = $pathsCombined.Where({
        [System.IO.File]::Exists($_)
    })
    if (-not $pathsExists) {
        Write-Warning -Message $timeStamp.GetStamp("The file `'$FileName`' was not found in default locations!")
        return
    }
    Write-Verbose -Message $timeStamp.GetStamp("The file `'$FileName`' was found in $($pathsExists.Count) location(s). Returning list of paths.")
    return $pathsExists
}