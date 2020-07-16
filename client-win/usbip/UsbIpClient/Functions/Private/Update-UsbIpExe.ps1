function Update-UsbIpExe {
    [CmdletBinding()]
    param (
        # Path to the USBIP executable file
        [Parameter(Mandatory)]
        [string]
        $Path
    )
    [string]$myName = "$($MyInvocation.InvocationName):"

    #   Some constants:
    ##  Addresses
    [int[]]$addrInt32 = @(
        3260    #   Hex: 00000CBC
        3594    #   Hex: 00000E0A
    )
    ##  Value to set:
    [int]$valueToSet = 17   #   Hex: 00000011
    ##  FileSize:
    [int]$fileSize = 94208
    # End of constants.

    Write-Verbose -Message "$myName Starting the function with path: $Path"
    if (-not [System.IO.File]::Exists($Path))
    {
        Write-Warning -Message "$myName The file does not exists! Exiting."
        return $false
    }

    [string]$pathToBackup = [System.IO.Path]::ChangeExtension($Path, '.bak')
    if ([System.IO.File]::Exists($pathToBackup)) {
        Write-Warning -Message "$myName The backup file already found: $($pathToBackup)! Removing..."
        [System.IO.File]::Delete($pathToBackup)
    }

    Write-Verbose -Message "$myName Backup the source file `"$Path`" to destination `"$pathToBackup`"."
    [System.IO.File]::Copy($Path, $pathToBackup)

    Write-Verbose -Message "$myName Read bytes from the file: $Path"
    try
    {
        [byte[]]$bytesFromFile = [System.IO.File]::ReadAllBytes($Path)
    }
    catch [System.UnauthorizedAccessException]
    {
        Write-Warning -Message "$myName Access is denied: $Path! Check and fix the rights for the current user: $($env:USERNAME)! Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $false
    }
    catch
    {
        Write-Warning -Message "$myName Cannot read the file: $Path! Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $false
    }

    if (-not $bytesFromFile) {
        Write-Warning -Message "$myName The file is empty! Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $false
    }

    if ($bytesFromFile.Count -lt [System.Linq.Enumerable]::Max($addrInt32)) {
        Write-Warning -Message "$myName The file size $($bytesFromFile.Count) is less than the max address! Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $false
    }
    
    if ($bytesFromFile.Count -lt $fileSize) {
        Write-Warning -Message "$myName The file size $($bytesFromFile.Count) is less than the expected file size $fileSize! Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $false
    }

    [int[]]$addrToFix = @()
    
    $addrInt32.ForEach({
        [int]$addrCurr = $_
        Write-Verbose -Message "$myName Reading byte at address: $addrCurr"
        if ($bytesFromFile[$addrCurr] -ne $valueToSet) {
            Write-Verbose -Message "$myName Address: $($addrCurr); current value: $($bytesFromFile[$addrCurr]); must be: $($valueToSet)."
            $addrToFix += $addrCurr
        }
        else {
            Write-Verbose -Message "$myName Address: $($addrCurr); current value $($bytesFromFile[$addrCurr]) is equal to the expected value: $($valueToSet)."
        }
    })

    if (-not $addrToFix)
    {
        Write-Verbose -Message "$myName Seems like the file `"$Path`" was already patched. Nothing to do. Removing the backup and exiting."
        [System.IO.File]::Delete($pathToBackup)
        return $true
    }

    $addrToFix.ForEach({
        Write-Verbose -Message "$myName Fixing the value at the address: $_"
        $bytesFromFile[$_] = $valueToSet
    })

    Write-Verbose -Message "$myName Write the patched file: $Path"
    try {
        [System.IO.File]::WriteAllBytes($Path, $bytesFromFile)
    }
    catch {
        Write-Warning -Message "$myName Cannot write the patched file! Something gone wrong. Backup should be here: $pathToBackup"
        return $false
    }

    Write-Verbose -Message "$myName Removing the backup. End of the function."
    [System.IO.File]::Delete($pathToBackup)
    return $true
}
