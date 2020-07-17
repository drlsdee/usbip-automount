[string]$classesFolderPath = "$PSScriptRoot\Classes"
if ([System.IO.Directory]::Exists($classesFolderPath)) {
    [string[]]$classesList = [System.IO.Directory]::EnumerateFiles($classesFolderPath, '*.ps1', 'AllDirectories')
}

if ($classesList) {
    Write-Verbose -Message "Found $($classesList.Count) script(s) containing custom PowerShell classes. Importing..."
    $classesList.ForEach({
        [string]$classFullName = $_
        [string]$classBaseName = [System.IO.Path]::GetFileNameWithoutExtension($_)
        try {
            . $classFullName
        }
        catch [System.Management.Automation.CommandNotFoundException]
        {
            Write-Warning -Message "The class `"$classBaseName`" is invalid! Skipping."
        }
        catch # All other errors
        {
            Write-Warning -Message "Cannot import the class `"$($classBaseName)`"!"
            $_
        }
    })
}
<# 
[string]$psDscResourcesFolderPath = "$PSScriptRoot\DscResources"
if ([System.IO.Directory]::Exists($psDscResourcesFolderPath)) {
    [string[]]$psDscResourcesList = [System.IO.Directory]::EnumerateFiles($psDscResourcesFolderPath, '*.psm1', 'AllDirectories')
}

if ($psDscResourcesList) {
    Write-Verbose -Message "Found $($psDscResourcesList.Count) script(s) containing custom PowerShell DSC resources. Importing..."
    $psDscResourcesList.ForEach({
        [string]$psDscResourceFullName = $_
        [string]$psDscResourceBaseName = [System.IO.Path]::GetFileNameWithoutExtension($_)
        try {
            #. $psDscResourceFullName
            Import-Module -Name $psDscResourceFullName
        }
        catch [System.Management.Automation.CommandNotFoundException]
        {
            Write-Warning -Message "The DSC resource `"$psDscResourceBaseName`" is invalid! Skipping."
        }
        catch # All other errors
        {
            Write-Warning -Message "Cannot import the DSC resource `"$($psDscResourceBaseName)`"!"
            $_
        }
    })
}
 #>
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

Write-Verbose -Message "Found $($functionsAll.Count) function(s), including $($functionsPublic.Count) public and $($functionsPrivate.Count) private function(s). Importing..."
$functionsAll.ForEach({
    [string]$functionFullName   = $_
    [string]$functionBaseName   = [System.IO.Path]::GetFileNameWithoutExtension($_)
    Write-Verbose -Message "Dot sourcing the function `"$($functionBaseName)`" from path `"$($functionFullName)`"..."
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

Write-Verbose -Message "Exporting functions and aliases..."
$functionsPublic.ForEach({
    [string]$functionBaseName   = [System.IO.Path]::GetFileNameWithoutExtension($_)
    Write-Verbose -Message "Exporting function: $functionBaseName"
    Export-ModuleMember -Function $functionBaseName
    try {
        [string[]]$aliasNames = Get-Alias -Definition $functionBaseName -ErrorAction Stop
        $aliasNames.ForEach({
            [string]$aliasName = $_
            Write-Verbose -Message "Found alias `"$($aliasName)`" for function `"$($functionBaseName)`". Exporting..."
            Export-ModuleMember -Alias $aliasName
        })
    } catch {
        Write-Warning -Message "Function `"$($functionBaseName)`" has no aliases!"
    }
})
