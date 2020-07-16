function Find-UsbIpDistributive {
    [CmdletBinding()]
    param (
        # Path to the distributive folder
        [Parameter(Mandatory)]
        [string]
        $Path
    )
    [LogStamp]$timeStamp = [LogStamp]::new([System.String]$MyInvocation.InvocationName)
    Write-Verbose -Message $timeStamp.GetStamp('Starting the function...')
    if (-not [System.IO.Directory]::Exists($Path)) {
        Write-Warning -Message $timeStamp.GetStamp("The folder `'$Path`' does not exist! Exiting.")
        return $false
    }

    [string[]]$filesFound = [System.IO.Directory]::EnumerateFiles($Path)
    if (-not $filesFound) {
        Write-Warning -Message $timeStamp.GetStamp("The folder `'$Path`' is empty! Exiting.")
        return $false
    }
    Write-Verbose -Message $timeStamp.GetStamp("Found $($filesFound.Count) files total in the folder `'$Path`'. Continue.")

    [string[]]$filesMustPresent = @(
        'USAGE',
        'usb.ids',
        'usbip.exe',
        'usbipenum.cat',
        'USBIPEnum.inf',
        'USBIPEnum_x64.sys',
        'USBIPEnum_x86.sys'
    ).ForEach({
        [System.IO.Path]::Combine($Path, $_)
    })

    [string[]]$filesAbsent = @()

    $filesMustPresent.ForEach({
        [string]$fileName = $_
        if ($filesFound.Contains($_))
        {
            Write-Verbose -Message $timeStamp.GetStamp("The file `'$fileName`' found in the folder `'$Path`'.")
        }
        else {
            Write-Warning -Message $timeStamp.GetStamp("The file `'$fileName`' was not found in the folder `'$Path`'!")
            $filesAbsent += $fileName
        }
    })

    if ($filesAbsent) {
        Write-Warning -Message $timeStamp.GetStamp("The folder `'$Path`' does not contain $($filesAbsent.Count) necessary files! Exiting.")
        return $false
    }

    Write-Verbose -Message $timeStamp.GetStamp("Found all of the $($filesMustPresent.Count) necessary files in the folder `'$Path`'. Returning `'$true`'")
    return $true
}