[string]$classesFolderPath = "$PSScriptRoot\Classes"
if ([System.IO.Directory]::Exists($classesFolderPath)) {
    [string[]]$classesList = [System.IO.Directory]::EnumerateFiles($classesFolderPath, '*.ps1', 'AllDirectories')
}

if ($classesList) {
    Write-Verbose -Message "Found $($classesList.Count) script(s) containing custom PowerShell classes. Importing..." -Verbose
    $classesList.ForEach({
        [string]$classFullName = $_
        [string]$classBaseName = [System.IO.Path]::GetFileNameWithoutExtension($_)
        try {
            . $classFullName
        }
        catch [System.Management.Automation.CommandNotFoundException]
        {
            Write-Warning -Message "The class `"$classBaseName`" is invalid! Skipping." -Verbose
        }
        catch # All other errors
        {
            Write-Warning -Message "Cannot import the class `"$($classBaseName)`"!"
            $_
        }
    })
}

[string]$functionsFolderPath = "$PSScriptRoot\Functions"
[string]$functionsFolderPathPrivate = "$functionsFolderPath\Private"
[string]$functionsFolderPathPublic = "$functionsFolderPath\Public"

if ([System.IO.Directory]::Exists($functionsFolderPathPrivate)) {
    [string[]]$functionsPrivate = [System.IO.Directory]::EnumerateFiles($functionsFolderPathPrivate, '*.ps1')
}

if ([System.IO.Directory]::Exists($functionsFolderPathPublic)) {
    [string[]]$functionsPublic  = [System.IO.Directory]::EnumerateFiles($functionsFolderPathPublic, '*.ps1')
}

[string[]]$functionsAll = @(
    $functionsPrivate
    $functionsPublic
).Where({$_})

Write-Verbose -Message "Found $($functionsAll.Count) function(s), including $($functionsPublic.Count) public and $($functionsPrivate.Count) private function(s). Importing..." -Verbose
$functionsAll.ForEach({
    [string]$functionFullName   = $_
    [string]$functionBaseName   = [System.IO.Path]::GetFileNameWithoutExtension($_)
    Write-Verbose -Message "Dot sourcing the function `"$($functionBaseName)`" from path `"$($functionFullName)`"..." -Verbose
    try {
        . $functionFullName
    }
    catch [System.Management.Automation.CommandNotFoundException]
    {
        Write-Warning -Message "The function `"$functionBaseName`" is invalid! Skipping."
    }
    catch # All other errors
    {
        Write-Warning -Message "Cannot import the function `"$($functionBaseName)`"!"
        $_
    }
})

Write-Verbose -Message "Exporting functions and aliases..." -Verbose
$functionsPublic.ForEach({
    [string]$functionBaseName   = [System.IO.Path]::GetFileNameWithoutExtension($_)
    Write-Verbose -Message "Exporting function: $functionBaseName" -Verbose
    Export-ModuleMember -Function $functionBaseName
    try {
        [string[]]$aliasNames = Get-Alias -Definition $functionBaseName -ErrorAction Stop
        $aliasNames.ForEach({
            [string]$aliasName = $_
            Write-Verbose -Message "Found alias `"$($aliasName)`" for function `"$($functionBaseName)`". Exporting..." -Verbose
            Export-ModuleMember -Alias $aliasName
        })
    } catch {
        Write-Warning -Message "Function `"$($functionBaseName)`" has no aliases!"
    }
})
